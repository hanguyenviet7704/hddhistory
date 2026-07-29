import React, { useCallback, useEffect, useMemo, useRef, useState } from "react";
import { useSelector } from "react-redux";
import {
  AlertTriangleIcon,
  Loader2Icon,
  RefreshCwIcon,
  SearchIcon,
  Volume2Icon,
  ZapIcon,
} from "lucide-react";
import { RootState } from "../../store";
import { getTranslationValue } from "../../utils/translation";
import { useNotification } from "../../utils/hooks/useNotification";
import VoiceoverStatusModal from "../../components/courses/VoiceoverStatusModal";
import {
  voiceoverService,
  CourseVoiceoverSummary,
  GlobalVoiceoverStatus,
  VoiceoverCellStatus,
  VoiceoverVoiceSelection,
} from "../../services/voiceoverService";
import VoiceoverVoicePicker from "../../components/courses/VoiceoverVoicePicker";

// Stat cards mirror VoiceoverStatusModal's SUMMARY, plus a Total tile since
// the global report already carries an aggregate count.
const STAT_CARDS: Array<{
  key: VoiceoverCellStatus | "total";
  label: string;
  hint: string;
  color: string;
}> = [
  { key: "done", label: "Done", hint: "Đã có audio khớp", color: "text-green-600" },
  { key: "stale", label: "Stale", hint: "Nội dung đã đổi", color: "text-amber-600" },
  { key: "missing", label: "Missing", hint: "Có nội dung, chưa audio", color: "text-sky-600" },
  { key: "failed", label: "Failed", hint: "Lỗi, xem bên dưới", color: "text-red-600" },
  { key: "none", label: "Không có text", hint: "Không có gì để đọc", color: "text-gray-400" },
  { key: "total", label: "Total", hint: "Tổng số ô ngôn ngữ × keypoint", color: "text-indigo-600" },
];

const CHIP_CLASS: Record<VoiceoverCellStatus, string> = {
  done: "bg-green-100 text-green-700",
  stale: "bg-amber-100 text-amber-700",
  missing: "bg-sky-100 text-sky-700",
  failed: "bg-red-100 text-red-700",
  none: "bg-gray-100 text-gray-500",
};

const CHIP_LABEL: Record<VoiceoverCellStatus, string> = {
  done: "Done",
  stale: "Stale",
  missing: "Missing",
  failed: "Failed",
  none: "Không có text",
};

const STATE_FILTERS: Array<{ value: VoiceoverCellStatus | "all"; label: string }> = [
  { value: "all", label: "Tất cả trạng thái" },
  { value: "done", label: "Done" },
  { value: "stale", label: "Stale" },
  { value: "missing", label: "Missing" },
  { value: "failed", label: "Failed" },
  { value: "none", label: "Không có text" },
];

export default function VoiceoverBatch() {
  const lang = useSelector((state: RootState) => state.lang.code);
  const { showSuccess, showError } = useNotification();

  const [status, setStatus] = useState<GlobalVoiceoverStatus | null>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [starting, setStarting] = useState<"needed" | "force" | null>(null);
  const [confirmForce, setConfirmForce] = useState(false);

  const [search, setSearch] = useState("");
  const [stateFilter, setStateFilter] = useState<VoiceoverCellStatus | "all">("all");
  const [langFilter, setLangFilter] = useState<string>("all");

  const [drillCourse, setDrillCourse] = useState<CourseVoiceoverSummary | null>(null);
  const [rowDubbing, setRowDubbing] = useState<Set<string>>(new Set());

  const wasRunningRef = useRef(false);
  const pollRef = useRef<number | undefined>(undefined);

  const load = useCallback(async () => {
    try {
      const res = await voiceoverService.getGlobalStatus();
      setStatus((res?.data ?? res) as GlobalVoiceoverStatus);
      setError(null);
    } catch (err: any) {
      setError(
        err?.response?.data?.message ||
          err?.message ||
          "Failed to load voiceover coverage"
      );
    } finally {
      setLoading(false);
    }
  }, []);

  useEffect(() => {
    load();
  }, [load]);

  const job = status?.job ?? null;
  const running = job?.status === "running";

  // Poll while a global batch job is running; back off to 30s in a hidden
  // tab, same convention as CourseImportJobDetail.
  useEffect(() => {
    window.clearTimeout(pollRef.current);
    if (!running) return;
    const delay = document.hidden ? 30000 : 3000;
    pollRef.current = window.setTimeout(load, delay);
    return () => window.clearTimeout(pollRef.current);
  }, [running, job, load]);

  // Announce completion once, on the running -> done/failed transition.
  useEffect(() => {
    if (running) {
      wasRunningRef.current = true;
      return;
    }
    if (wasRunningRef.current && job) {
      wasRunningRef.current = false;
      if (job.status === "failed") {
        showError(`Job lồng tiếng thất bại: ${job.lastError ?? "lỗi không rõ"}`);
      } else {
        showSuccess(
          `Đã dub xong: ${job.generated} tạo mới, ${job.skipped} bỏ qua` +
            (job.failed ? `, ${job.failed} lỗi` : "")
        );
      }
    }
  }, [running, job, showError, showSuccess]);

  const handleScan = () => {
    setLoading(true);
    load();
  };

  // Narrator applied to every run started from this page (batch, force, or a
  // single course row). The backend remembers the narrator per keypoint, so a
  // "dub what's missing" run at the default still leaves already-dubbed
  // keypoints on the voice they were made with.
  const [voices, setVoices] = useState<VoiceoverVoiceSelection>({});

  const handleGenerateNeeded = async () => {
    if (running || starting) return;
    setStarting("needed");
    try {
      await voiceoverService.generateAll(false, voices);
      showSuccess("Đã bắt đầu dub những bài còn thiếu ở nền…");
      await load();
    } catch (err: any) {
      showError(
        err?.response?.data?.message || "Failed to start voiceover batch"
      );
    } finally {
      setStarting(null);
    }
  };

  const handleForceAll = async () => {
    if (running || starting) return;
    setConfirmForce(false);
    setStarting("force");
    try {
      await voiceoverService.generateAll(true, voices);
      showSuccess("Đã bắt đầu force dub lại toàn bộ ở nền…");
      await load();
    } catch (err: any) {
      showError(
        err?.response?.data?.message || "Failed to start voiceover batch"
      );
    } finally {
      setStarting(null);
    }
  };

  const handleRowDub = async (course: CourseVoiceoverSummary) => {
    if (running || rowDubbing.has(course.courseId)) return;
    setRowDubbing((prev) => new Set(prev).add(course.courseId));
    try {
      await voiceoverService.generateForCourse(course.courseId, voices);
      showSuccess(
        `Đã bắt đầu dub cho "${getTranslationValue(course.title, lang) || course.courseId}"`
      );
      await load();
    } catch (err: any) {
      showError(
        err?.response?.data?.message || "Failed to start course voiceover"
      );
    } finally {
      setRowDubbing((prev) => {
        const next = new Set(prev);
        next.delete(course.courseId);
        return next;
      });
    }
  };

  const langs = status?.langs ?? [];

  const filteredCourses = useMemo(() => {
    const q = search.trim().toLowerCase();
    return (status?.courses ?? []).filter((c) => {
      if (stateFilter !== "all" && (c.summary?.[stateFilter] ?? 0) === 0) {
        return false;
      }
      if (!q) return true;
      const title = getTranslationValue(c.title, lang).toLowerCase();
      return title.includes(q) || c.courseId.toLowerCase().includes(q);
    });
  }, [status, stateFilter, search, lang]);

  const filtersActive = search.trim() !== "" || stateFilter !== "all";
  const resetFilters = () => {
    setSearch("");
    setStateFilter("all");
    setLangFilter("all");
  };

  if (loading && !status) {
    return (
      <div className="min-h-[100dvh] bg-slate-100 px-4 py-10">
        <div className="mx-auto flex max-w-6xl justify-center">
          <div className="flex items-center gap-3 rounded-lg border border-slate-200 bg-white px-5 py-4 text-slate-700 shadow-sm">
            <Loader2Icon className="h-5 w-5 animate-spin text-indigo-600" />
            Đang tải dữ liệu lồng tiếng…
          </div>
        </div>
      </div>
    );
  }

  return (
    <div className="min-h-[100dvh] bg-slate-100 px-4 py-8 text-slate-900 md:px-8">
      <div className="mx-auto max-w-6xl space-y-6">
        {/* Header */}
        <div className="flex flex-col gap-4 rounded-xl border border-slate-200 bg-white p-6 shadow-sm md:flex-row md:items-center md:justify-between">
          <div>
            <h1 className="flex items-center gap-2 text-2xl font-semibold text-slate-950">
              <Volume2Icon className="h-6 w-6 text-indigo-600" />
              Lồng tiếng
            </h1>
            <p className="mt-1 text-sm text-slate-500">
              Theo dõi độ phủ audio TTS theo course và chạy dub hàng loạt.
            </p>
          </div>
          <div className="flex flex-wrap items-center gap-2">
            <VoiceoverVoicePicker
              value={voices}
              onChange={setVoices}
              disabled={running || starting !== null}
            />
            <button
              type="button"
              onClick={handleScan}
              disabled={loading}
              className="inline-flex items-center gap-2 rounded-lg border border-slate-300 bg-white px-4 py-2 text-sm font-medium text-slate-700 shadow-sm transition hover:bg-slate-50 disabled:opacity-60"
            >
              <RefreshCwIcon className={`h-4 w-4 ${loading ? "animate-spin" : ""}`} />
              Quét
            </button>
            <button
              type="button"
              onClick={handleGenerateNeeded}
              disabled={running || starting !== null}
              className="inline-flex items-center gap-2 rounded-lg bg-indigo-600 px-4 py-2 text-sm font-medium text-white shadow-sm transition hover:bg-indigo-700 disabled:opacity-60"
            >
              <Volume2Icon className="h-4 w-4" />
              {starting === "needed" ? "Đang bắt đầu…" : "Dub những cái cần"}
            </button>
            <button
              type="button"
              onClick={() => setConfirmForce(true)}
              disabled={running || starting !== null}
              className="inline-flex items-center gap-2 rounded-lg border border-amber-300 bg-amber-50 px-4 py-2 text-sm font-medium text-amber-800 shadow-sm transition hover:bg-amber-100 disabled:opacity-60"
            >
              <ZapIcon className="h-4 w-4" />
              {starting === "force" ? "Đang bắt đầu…" : "Force dub lại tất cả"}
            </button>
          </div>
        </div>

        {error && (
          <div className="flex items-start justify-between gap-3 rounded-lg border border-red-200 bg-red-50 px-4 py-3 text-sm text-red-700 shadow-sm">
            <span className="flex items-start gap-2">
              <AlertTriangleIcon className="mt-0.5 h-5 w-5 flex-none" />
              {error}
            </span>
            <button
              type="button"
              onClick={handleScan}
              className="shrink-0 rounded-md border border-red-300 bg-white px-3 py-1 text-xs font-medium text-red-700 hover:bg-red-100"
            >
              Retry
            </button>
          </div>
        )}

        {/* Running global job banner */}
        {job && job.status === "running" && (
          <div className="rounded-xl border border-indigo-200 bg-indigo-50 p-4 shadow-sm">
            <div className="flex flex-wrap items-center justify-between gap-2 text-sm text-indigo-800">
              <span className="flex items-center gap-2 font-medium">
                <Loader2Icon className="h-4 w-4 animate-spin" />
                Đang {job.mode === "force" ? "force dub" : "dub"} ở nền…{" "}
                {job.processedCourses}/{job.totalCourses} course ·{" "}
                {job.processed}/{job.totalKeypoints} keypoint
              </span>
              <span className="text-xs text-indigo-500">tự cập nhật mỗi 3s</span>
            </div>
            <div className="mt-2 h-2 w-full overflow-hidden rounded-full bg-indigo-100">
              <div
                className="h-full rounded-full bg-indigo-500 transition-all"
                style={{
                  width: `${
                    job.totalKeypoints
                      ? (job.processed / job.totalKeypoints) * 100
                      : 0
                  }%`,
                }}
              />
            </div>
            <div className="mt-2 flex flex-wrap gap-x-4 gap-y-1 text-xs text-indigo-700">
              <span>Đã tạo: {job.generated}</span>
              <span>Bỏ qua: {job.skipped}</span>
              <span>Lỗi: {job.failed}</span>
              {job.currentCourseId && (
                <span className="truncate">
                  Course hiện tại: {job.currentCourseId}
                </span>
              )}
            </div>
          </div>
        )}
        {job && job.status === "failed" && !running && (
          <div className="flex items-start gap-2 rounded-lg border border-red-200 bg-red-50 px-4 py-3 text-sm text-red-700 shadow-sm">
            <AlertTriangleIcon className="mt-0.5 h-5 w-5 flex-none" />
            Job lồng tiếng lần trước thất bại: {job.lastError ?? "lỗi không rõ"}
          </div>
        )}

        {/* Stat cards */}
        <div className="grid grid-cols-2 gap-3 sm:grid-cols-3 lg:grid-cols-6">
          {STAT_CARDS.map((s) => (
            <div key={s.key} className="rounded-lg border border-slate-200 bg-white p-3 shadow-sm">
              <div className="text-xs uppercase tracking-wide text-slate-500">
                {s.label}
              </div>
              <div className={`mt-1 text-2xl font-semibold ${s.color}`}>
                {status?.summary?.[s.key] ?? 0}
              </div>
              <div className="mt-1 text-xs text-slate-400">{s.hint}</div>
            </div>
          ))}
        </div>

        {/* Filters */}
        <div className="flex flex-col gap-3 rounded-xl border border-slate-200 bg-white p-4 shadow-sm md:flex-row md:items-end md:justify-between">
          <div className="flex flex-1 flex-wrap items-end gap-3">
            <div className="w-full max-w-xs">
              <label className="mb-1 block text-xs font-medium text-slate-500">
                Tìm course
              </label>
              <div className="relative">
                <SearchIcon className="pointer-events-none absolute left-3 top-1/2 h-4 w-4 -translate-y-1/2 text-slate-400" />
                <input
                  type="text"
                  value={search}
                  onChange={(e) => setSearch(e.target.value)}
                  placeholder="Tên course…"
                  className="w-full rounded-lg border border-slate-300 py-2 pl-9 pr-3 text-sm shadow-sm focus:outline-none focus:ring-2 focus:ring-indigo-400"
                />
              </div>
            </div>

            <div>
              <label className="mb-1 block text-xs font-medium text-slate-500">
                Trạng thái
              </label>
              <select
                value={stateFilter}
                onChange={(e) =>
                  setStateFilter(e.target.value as VoiceoverCellStatus | "all")
                }
                className="rounded-lg border border-slate-300 py-2 pl-3 pr-8 text-sm shadow-sm focus:outline-none focus:ring-2 focus:ring-indigo-400"
              >
                {STATE_FILTERS.map((f) => (
                  <option key={f.value} value={f.value}>
                    {f.label}
                  </option>
                ))}
              </select>
            </div>

            <div>
              <label className="mb-1 block text-xs font-medium text-slate-500">
                Ngôn ngữ
              </label>
              <select
                value={langFilter}
                onChange={(e) => setLangFilter(e.target.value)}
                className="rounded-lg border border-slate-300 py-2 pl-3 pr-8 text-sm shadow-sm focus:outline-none focus:ring-2 focus:ring-indigo-400"
              >
                <option value="all">Tất cả ngôn ngữ</option>
                {langs.map((lg) => (
                  <option key={lg} value={lg}>
                    {lg.toUpperCase()}
                  </option>
                ))}
              </select>
              <p className="mt-1 max-w-[12rem] text-[11px] text-slate-400">
                Tô sáng cột tương ứng khi mở Chi tiết course
              </p>
            </div>
          </div>

          {filtersActive && (
            <button
              type="button"
              onClick={resetFilters}
              className="rounded-lg border border-slate-300 bg-white px-3 py-2 text-xs font-medium text-slate-600 shadow-sm hover:bg-slate-50"
            >
              Xóa bộ lọc
            </button>
          )}
        </div>

        {/* Table */}
        <div className="overflow-hidden rounded-xl border border-slate-200 bg-white shadow-sm">
          {(status?.courses.length ?? 0) === 0 ? (
            <div className="py-16 text-center">
              <Volume2Icon className="mx-auto h-10 w-10 text-slate-300" />
              <h3 className="mt-3 text-base font-medium text-slate-900">
                Chưa có dữ liệu lồng tiếng
              </h3>
              <p className="mt-1 text-sm text-slate-500">
                Bấm Quét để tải độ phủ audio của tất cả course.
              </p>
              <button
                type="button"
                onClick={handleScan}
                className="mt-4 inline-flex items-center gap-2 rounded-lg bg-indigo-600 px-4 py-2 text-sm font-medium text-white shadow-sm hover:bg-indigo-700"
              >
                <RefreshCwIcon className="h-4 w-4" />
                Quét ngay
              </button>
            </div>
          ) : filteredCourses.length === 0 ? (
            <div className="py-16 text-center">
              <SearchIcon className="mx-auto h-10 w-10 text-slate-300" />
              <h3 className="mt-3 text-base font-medium text-slate-900">
                Không có course nào khớp bộ lọc
              </h3>
              <p className="mt-1 text-sm text-slate-500">
                Thử đổi từ khóa tìm kiếm hoặc trạng thái.
              </p>
              <button
                type="button"
                onClick={resetFilters}
                className="mt-4 inline-flex items-center gap-2 rounded-lg border border-slate-300 bg-white px-4 py-2 text-sm font-medium text-slate-700 shadow-sm hover:bg-slate-50"
              >
                Xóa bộ lọc
              </button>
            </div>
          ) : (
            <div className="overflow-x-auto">
              <table className="min-w-full text-sm">
                <thead className="border-b border-slate-200 bg-slate-50">
                  <tr className="text-left text-slate-500">
                    <th className="px-4 py-3 font-medium">Course</th>
                    <th className="px-4 py-3 text-center font-medium">Keypoint</th>
                    <th className="px-4 py-3 font-medium">Độ phủ</th>
                    <th className="px-4 py-3 text-right font-medium">Hành động</th>
                  </tr>
                </thead>
                <tbody className="divide-y divide-slate-100">
                  {filteredCourses.map((course) => {
                    const title = getTranslationValue(course.title, lang) || course.courseId;
                    const busy = rowDubbing.has(course.courseId);
                    return (
                      <tr key={course.courseId} className="align-top hover:bg-indigo-50/30">
                        <td className="max-w-xs px-4 py-3">
                          <p className="truncate font-medium text-slate-900" title={title}>
                            {title}
                          </p>
                          <p className="truncate text-xs text-slate-400">{course.courseId}</p>
                        </td>
                        <td className="px-4 py-3 text-center text-slate-600">
                          {course.keypointCount}
                        </td>
                        <td className="px-4 py-3">
                          <div className="flex flex-wrap gap-1">
                            {(Object.keys(CHIP_LABEL) as VoiceoverCellStatus[])
                              .filter((k) => (course.summary?.[k] ?? 0) > 0)
                              .map((k) => (
                                <span
                                  key={k}
                                  className={`inline-flex items-center rounded-full px-2 py-0.5 text-xs font-semibold ${CHIP_CLASS[k]}`}
                                >
                                  {course.summary[k]} {CHIP_LABEL[k]}
                                </span>
                              ))}
                            {Object.values(course.summary ?? {}).every((v) => !v) && (
                              <span className="text-xs text-slate-400">Không có dữ liệu</span>
                            )}
                          </div>
                        </td>
                        <td className="px-4 py-3 text-right">
                          <div className="flex justify-end gap-2">
                            <button
                              type="button"
                              onClick={() => setDrillCourse(course)}
                              className="rounded-md border border-slate-300 bg-white px-2.5 py-1 text-xs font-medium text-slate-700 hover:bg-slate-50"
                            >
                              Chi tiết
                            </button>
                            <button
                              type="button"
                              onClick={() => handleRowDub(course)}
                              disabled={running || busy}
                              className="inline-flex items-center gap-1 rounded-md bg-indigo-600 px-2.5 py-1 text-xs font-medium text-white hover:bg-indigo-700 disabled:opacity-50"
                            >
                              {busy ? (
                                <Loader2Icon className="h-3.5 w-3.5 animate-spin" />
                              ) : (
                                <Volume2Icon className="h-3.5 w-3.5" />
                              )}
                              Dub
                            </button>
                          </div>
                        </td>
                      </tr>
                    );
                  })}
                </tbody>
              </table>
            </div>
          )}
        </div>
      </div>

      {/* Per-course drill-down */}
      <VoiceoverStatusModal
        open={Boolean(drillCourse)}
        courseId={drillCourse?.courseId ?? ""}
        courseTitle={
          drillCourse ? getTranslationValue(drillCourse.title, lang) || drillCourse.courseId : ""
        }
        highlightLang={langFilter !== "all" ? langFilter : undefined}
        onClose={() => setDrillCourse(null)}
      />

      {/* Force dub confirmation */}
      {confirmForce && (
        <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/50 px-4">
          <div className="w-full max-w-md space-y-4 rounded-xl border border-gray-100 bg-white p-6 shadow-2xl">
            <h3 className="flex items-center gap-2 text-lg font-bold text-gray-900">
              <AlertTriangleIcon className="h-6 w-6 text-amber-500" />
              Force dub lại tất cả?
            </h3>
            <p className="text-sm leading-relaxed text-gray-600">
              Thao tác này sẽ tạo lại audio cho toàn bộ keypoint × ngôn ngữ của
              mọi course, kể cả những bài đã có audio hợp lệ. Việc này có thể
              mất nhiều thời gian và tốn chi phí TTS.
            </p>
            <div className="flex justify-end gap-3 pt-2">
              <button
                type="button"
                onClick={() => setConfirmForce(false)}
                className="rounded-lg border border-gray-200 bg-white px-4 py-2 text-sm font-medium text-gray-700 transition hover:bg-gray-50"
              >
                Hủy
              </button>
              <button
                type="button"
                onClick={handleForceAll}
                className="rounded-lg bg-amber-600 px-4 py-2 text-sm font-semibold text-white transition hover:bg-amber-700"
              >
                Force dub tất cả
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}
