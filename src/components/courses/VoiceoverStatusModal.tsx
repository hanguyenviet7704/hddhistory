import React, { useCallback, useEffect, useRef, useState } from "react";
import { RefreshCwIcon, Volume2Icon, XIcon } from "lucide-react";
import { useSelector } from "react-redux";
import { RootState } from "../../store";
import { getTranslationValue } from "../../utils/translation";
import { useNotification } from "../../utils/hooks/useNotification";
import {
  voiceoverService,
  CourseVoiceoverStatus,
  VoiceoverCellStatus,
} from "../../services/voiceoverService";

interface Props {
  open: boolean;
  onClose: () => void;
  courseId: string;
  courseTitle: string;
  // Optional language code to highlight in the per-keypoint × language grid
  // (e.g. set from a language filter on a caller list page). Purely visual.
  highlightLang?: string;
}

// Summary cards (mirrors Artlexis DubQueueStatus): count per state, colour-coded.
const SUMMARY: Array<{
  key: VoiceoverCellStatus;
  label: string;
  hint: string;
  color: string;
}> = [
  { key: "done", label: "Done", hint: "Đã có audio khớp", color: "text-green-600" },
  { key: "stale", label: "Stale", hint: "Theory đã đổi", color: "text-amber-600" },
  { key: "missing", label: "Missing", hint: "Có theory, chưa audio", color: "text-sky-600" },
  { key: "failed", label: "Failed", hint: "Lỗi, xem bên dưới", color: "text-red-600" },
  { key: "none", label: "No theory", hint: "Không có gì để đọc", color: "text-gray-400" },
];

const CELL_CLASS: Record<VoiceoverCellStatus, string> = {
  done: "bg-green-100 text-green-700",
  stale: "bg-amber-100 text-amber-700",
  missing: "bg-sky-100 text-sky-700",
  failed: "bg-red-100 text-red-700",
  none: "bg-gray-100 text-gray-400",
};

const CELL_LABEL: Record<VoiceoverCellStatus, string> = {
  done: "✓",
  stale: "↻",
  missing: "—",
  failed: "✕",
  none: "·",
};

const VoiceoverStatusModal: React.FC<Props> = ({
  open,
  onClose,
  courseId,
  courseTitle,
  highlightLang,
}) => {
  const lang = useSelector((state: RootState) => state.lang.code);
  const { showSuccess, showError } = useNotification();

  const [status, setStatus] = useState<CourseVoiceoverStatus | null>(null);
  const [loading, setLoading] = useState(false);
  const [starting, setStarting] = useState(false);
  const wasRunningRef = useRef(false);

  const load = useCallback(async () => {
    setLoading(true);
    try {
      const res = await voiceoverService.getCourseStatus(courseId);
      setStatus((res?.data ?? res) as CourseVoiceoverStatus);
    } catch (err) {
      showError(
        (err as any)?.response?.data?.message || "Failed to load voiceover status"
      );
    } finally {
      setLoading(false);
    }
  }, [courseId, showError]);

  useEffect(() => {
    if (open) load();
    else setStatus(null);
  }, [open, load]);

  const job = status?.job ?? null;
  const running = job?.status === "running";

  // Auto-poll while a background job is running: each status update reschedules
  // the next poll; polling stops when the job finishes.
  useEffect(() => {
    if (!open || !running) return;
    const t = setTimeout(() => load(), 3000);
    return () => clearTimeout(t);
  }, [open, running, job, load]);

  // Announce completion once, when the job transitions running → done/failed.
  useEffect(() => {
    if (running) {
      wasRunningRef.current = true;
      return;
    }
    if (wasRunningRef.current && job) {
      wasRunningRef.current = false;
      if (job.status === "failed") {
        showError(`Voiceover job failed: ${job.lastError ?? "error"}`);
      } else {
        showSuccess(
          `Voiceover done: ${job.generated} generated, ${job.skipped} unchanged` +
            (job.failed ? `, ${job.failed} failed` : "")
        );
      }
    }
  }, [running, job, showSuccess, showError]);

  const handleGenerate = async () => {
    if (running || starting) return;
    setStarting(true);
    try {
      await voiceoverService.generateForCourse(courseId);
      showSuccess("Đã bắt đầu sinh voiceover ở nền…");
      await load(); // picks up the running job → auto-poll kicks in
    } catch (err) {
      showError(
        (err as any)?.response?.data?.message || "Failed to start voiceover"
      );
    } finally {
      setStarting(false);
    }
  };

  // Re-run voiceover for just one keypoint (synchronous per-keypoint endpoint,
  // regenerates all its languages). Used from the failed/stale/missing cells.
  const [retrying, setRetrying] = useState<Set<string>>(new Set());
  const handleRetryKeypoint = async (keypointId: string) => {
    if (retrying.has(keypointId) || running) return;
    setRetrying((prev) => new Set(prev).add(keypointId));
    try {
      await voiceoverService.generateForKeypoint(keypointId);
      await load();
    } catch (err) {
      showError(
        (err as any)?.response?.data?.message || "Failed to regenerate keypoint"
      );
    } finally {
      setRetrying((prev) => {
        const n = new Set(prev);
        n.delete(keypointId);
        return n;
      });
    }
  };

  if (!open) return null;

  const langs = status?.langs ?? [];
  const attention = (status?.keypoints ?? []).filter((k) =>
    Object.values(k.statuses).some((s) => s === "failed")
  );

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center bg-black bg-opacity-40 p-4">
      <div className="bg-white rounded-xl shadow-xl w-full max-w-4xl max-h-[90vh] overflow-y-auto">
        {/* Header */}
        <div className="flex items-center justify-between border-b px-6 py-4">
          <div>
            <h2 className="text-lg font-semibold flex items-center gap-2">
              <Volume2Icon className="h-5 w-5 text-indigo-600" />
              Voiceover status
            </h2>
            <p className="text-sm text-gray-500 truncate max-w-lg">{courseTitle}</p>
          </div>
          <div className="flex items-center gap-2">
            <button
              onClick={load}
              disabled={loading}
              className="inline-flex items-center gap-2 rounded-lg border border-gray-300 px-3 py-2 text-sm font-medium text-gray-700 transition hover:bg-gray-50 disabled:opacity-60"
            >
              <RefreshCwIcon className={`h-4 w-4 ${loading ? "animate-spin" : ""}`} />
              Refresh
            </button>
            <button
              onClick={handleGenerate}
              disabled={running || starting}
              className="inline-flex items-center gap-2 rounded-lg bg-indigo-600 px-4 py-2 text-sm font-medium text-white transition hover:bg-indigo-700 disabled:opacity-60"
            >
              <Volume2Icon className="h-4 w-4" />
              {running
                ? "Generating…"
                : starting
                ? "Starting…"
                : "Generate voiceover"}
            </button>
            <button
              onClick={onClose}
              className="p-2 rounded-full hover:bg-gray-100"
              aria-label="Close"
            >
              <XIcon className="h-5 w-5 text-gray-500" />
            </button>
          </div>
        </div>

        <div className="p-6 space-y-6">
          {loading && !status ? (
            <p className="text-sm text-gray-500 text-center py-10">Đang tải…</p>
          ) : !status ? (
            <p className="text-sm text-gray-500 text-center py-10">Không có dữ liệu.</p>
          ) : (
            <>
              {/* Running job progress */}
              {job && job.status === "running" && (
                <div className="rounded-lg border border-indigo-200 bg-indigo-50 p-4">
                  <div className="flex items-center justify-between text-sm text-indigo-800">
                    <span className="font-medium">
                      Đang sinh voiceover ở nền… {job.processed}/{job.total}{" "}
                      keypoint
                    </span>
                    <span className="text-xs text-indigo-500">tự cập nhật</span>
                  </div>
                  <div className="mt-2 h-2 w-full overflow-hidden rounded-full bg-indigo-100">
                    <div
                      className="h-full rounded-full bg-indigo-500 transition-all"
                      style={{
                        width: `${
                          job.total ? (job.processed / job.total) * 100 : 0
                        }%`,
                      }}
                    />
                  </div>
                </div>
              )}

              {/* Summary cards */}
              <div className="grid grid-cols-2 sm:grid-cols-3 lg:grid-cols-5 gap-3">
                {SUMMARY.map((s) => (
                  <div
                    key={s.key}
                    className="rounded-lg border bg-white p-3 shadow-sm"
                  >
                    <div className="text-xs uppercase tracking-wide text-gray-500">
                      {s.label}
                    </div>
                    <div className={`mt-1 text-2xl font-semibold ${s.color}`}>
                      {status.summary?.[s.key] ?? 0}
                    </div>
                    <div className="mt-1 text-xs text-gray-400">{s.hint}</div>
                  </div>
                ))}
              </div>

              {/* Failed detail */}
              {attention.length > 0 && (
                <div className="rounded-lg border border-red-200 bg-red-50 p-4">
                  <h3 className="text-sm font-semibold text-red-800 mb-2">
                    Keypoint bị lỗi ({attention.length})
                  </h3>
                  <ul className="space-y-2 text-sm text-red-700">
                    {attention.map((k) => (
                      <li
                        key={k.keypointId}
                        className="flex items-start justify-between gap-3"
                      >
                        <div>
                          <span className="font-medium">
                            {getTranslationValue(k.title, lang) || k.keypointId}
                          </span>
                          {k.errors &&
                            Object.entries(k.errors).map(([lg, msg]) => (
                              <span
                                key={lg}
                                className="block pl-3 text-xs text-red-600"
                              >
                                [{lg}] {msg}
                              </span>
                            ))}
                        </div>
                        <button
                          type="button"
                          onClick={() => handleRetryKeypoint(k.keypointId)}
                          disabled={retrying.has(k.keypointId) || running}
                          className="shrink-0 inline-flex items-center gap-1 rounded-md border border-red-300 bg-white px-2.5 py-1 text-xs font-medium text-red-700 transition hover:bg-red-100 disabled:opacity-50"
                        >
                          <RefreshCwIcon
                            className={`h-3.5 w-3.5 ${
                              retrying.has(k.keypointId) ? "animate-spin" : ""
                            }`}
                          />
                          {retrying.has(k.keypointId) ? "Đang chạy…" : "Chạy lại"}
                        </button>
                      </li>
                    ))}
                  </ul>
                </div>
              )}

              {/* Per-keypoint × language grid */}
              <div className="overflow-x-auto">
                <table className="min-w-full text-sm">
                  <thead>
                    <tr className="text-left text-gray-500">
                      <th className="py-2 pr-4 font-medium">Keypoint</th>
                      {langs.map((lg) => (
                        <th
                          key={lg}
                          className={`py-2 px-2 font-medium text-center uppercase ${
                            lg === highlightLang
                              ? "bg-indigo-50 text-indigo-700 rounded-t"
                              : ""
                          }`}
                        >
                          {lg}
                        </th>
                      ))}
                    </tr>
                  </thead>
                  <tbody>
                    {status.keypoints.map((k, i) => (
                      <tr key={k.keypointId} className={i % 2 ? "bg-gray-50" : ""}>
                        <td className="py-2 pr-4 max-w-xs truncate">
                          {getTranslationValue(k.title, lang) || k.keypointId}
                        </td>
                        {langs.map((lg) => {
                          const st = (k.statuses?.[lg] ??
                            "none") as VoiceoverCellStatus;
                          const actionable =
                            st === "failed" || st === "stale" || st === "missing";
                          const busy = retrying.has(k.keypointId);
                          return (
                            <td
                              key={lg}
                              className={`py-2 px-2 text-center ${
                                lg === highlightLang ? "bg-indigo-50/60" : ""
                              }`}
                            >
                              {actionable ? (
                                <button
                                  type="button"
                                  onClick={() =>
                                    handleRetryKeypoint(k.keypointId)
                                  }
                                  disabled={busy || running}
                                  title={`${
                                    k.errors?.[lg] || st
                                  } — bấm để chạy lại bài này`}
                                  className={`inline-flex h-6 w-6 items-center justify-center rounded-full text-xs font-semibold ${CELL_CLASS[st]} transition hover:ring-2 hover:ring-indigo-300 disabled:opacity-50`}
                                >
                                  {busy ? "…" : CELL_LABEL[st]}
                                </button>
                              ) : (
                                <span
                                  title={st}
                                  className={`inline-flex h-6 w-6 items-center justify-center rounded-full text-xs font-semibold ${CELL_CLASS[st]}`}
                                >
                                  {CELL_LABEL[st]}
                                </span>
                              )}
                            </td>
                          );
                        })}
                      </tr>
                    ))}
                    {status.keypoints.length === 0 && (
                      <tr>
                        <td
                          colSpan={langs.length + 1}
                          className="py-6 text-center text-gray-400"
                        >
                          Course chưa có keypoint nào.
                        </td>
                      </tr>
                    )}
                  </tbody>
                </table>
                <p className="mt-3 text-xs text-gray-400">
                  ✓ done · ↻ stale (theory đổi) · — missing · ✕ failed · · no
                  theory — bấm vào ô ✕ / ↻ / — để chạy lại riêng bài đó.
                </p>
              </div>
            </>
          )}
        </div>
      </div>
    </div>
  );
};

export default VoiceoverStatusModal;
