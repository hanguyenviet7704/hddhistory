import React, { useCallback, useEffect, useMemo, useRef, useState } from "react";
import { useSelector } from "react-redux";
import {
  AlertTriangleIcon,
  CheckCircle2Icon,
  ClockIcon,
  Loader2Icon,
  PlayIcon,
  RefreshCwIcon,
  SearchIcon,
  Volume2Icon,
  ZapIcon,
} from "lucide-react";
import { RootState } from "../../store";
import { getTranslationValue } from "../../utils/translation";
import { useNotification } from "../../utils/hooks/useNotification";
import VoiceoverStatusModal from "../../components/courses/VoiceoverStatusModal";
import VbeeDubConfirmDialog from "../../components/courses/VbeeDubConfirmDialog";
import VbeeVoicePanel from "../../components/courses/VbeeVoicePanel";
import {
  voiceoverService,
  CourseVoiceoverSummary,
  GlobalVoiceoverStatus,
  VoiceoverCellStatus,
  VoiceoverJob,
  VoiceoverJobFeed,
  VoiceoverProviderKind,
  VoiceoverSettings,
} from "../../services/voiceoverService";

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

// Where a course sits in the run currently in flight. This is the answer to
// "cái nào đang trong tiến trình" — before, a row's Dub started a background job
// the page never displayed, and the only progress shown was the global banner's
// raw course id.
type RowRunState = "running" | "queued" | "done" | "failed" | "interrupted";

const ROW_BADGE: Record<
  RowRunState,
  { label: string; className: string; spinning?: boolean }
> = {
  running: {
    label: "Đang dub",
    className: "bg-indigo-100 text-indigo-700",
    spinning: true,
  },
  queued: { label: "Đang chờ", className: "bg-slate-100 text-slate-600" },
  done: { label: "Xong", className: "bg-green-100 text-green-700" },
  failed: { label: "Lỗi", className: "bg-red-100 text-red-700" },
  // Not the same thing as a failure: the run's process died (deploy/restart)
  // rather than the dubbing going wrong. Dub again to pick up where it stopped.
  interrupted: { label: "Bị ngắt", className: "bg-amber-100 text-amber-700" },
};

// The progress poll runs even when nothing is dubbing, just slowly, so a run
// started from another tab (or another admin) still shows up here.
const POLL_RUNNING_MS = 3000;
const POLL_IDLE_MS = 20000;
const POLL_HIDDEN_MS = 60000;

function formatEta(seconds: number | null | undefined): string | null {
  if (!seconds || seconds <= 0) return null;
  if (seconds < 60) return `${seconds}s`;

  const minutes = Math.round(seconds / 60);
  if (minutes < 60) return `${minutes} phút`;

  const hours = Math.floor(minutes / 60);
  const rest = minutes % 60;
  return rest ? `${hours}h${String(rest).padStart(2, "0")}` : `${hours}h`;
}

export default function VoiceoverBatch() {
  const lang = useSelector((state: RootState) => state.lang.code);
  const { showSuccess, showError } = useNotification();

  const [status, setStatus] = useState<GlobalVoiceoverStatus | null>(null);
  const [feed, setFeed] = useState<VoiceoverJobFeed | null>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [starting, setStarting] = useState<"needed" | "force" | "resume" | null>(
    null
  );
  const [startingRows, setStartingRows] = useState<Set<string>>(new Set());
  const [confirmForce, setConfirmForce] = useState(false);

  const [search, setSearch] = useState("");
  const [stateFilter, setStateFilter] = useState<VoiceoverCellStatus | "all">("all");
  const [langFilter, setLangFilter] = useState<string>("all");

  const [drillCourse, setDrillCourse] = useState<CourseVoiceoverSummary | null>(null);

  // Vbee: the shared narrator + which courses are opted in. Kept on this page
  // because the toggle belongs next to the coverage numbers it changes.
  const [settings, setSettings] = useState<VoiceoverSettings | null>(null);
  const [togglingRows, setTogglingRows] = useState<Set<string>>(new Set());
  // A Vbee dub spends real credit, so it goes through a confirm that shows the
  // counted cost first. Edge dubs still start on the first click.
  //
  // `switchToVbee` is set by the "Dub Vbee" shortcut on a course still on Edge:
  // the flag is flipped only AFTER the confirm, so backing out of the estimate
  // leaves the course exactly as it was.
  const [pendingDub, setPendingDub] = useState<{
    course: CourseVoiceoverSummary;
    switchToVbee: boolean;
  } | null>(null);

  const wasRunningRef = useRef(false);
  const pollRef = useRef<number | undefined>(undefined);

  // The full coverage scan. Reads every keypoint of every course, so it stays an
  // explicit action (first load + Quét + once a run ends) and never the poll.
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

  // The progress poll: one document per run in flight.
  const refreshJobs = useCallback(async () => {
    try {
      const res = await voiceoverService.getJobs();
      setFeed((res?.data ?? res) as VoiceoverJobFeed);
    } catch {
      // A dropped poll isn't worth an error banner — the next tick retries, and
      // the coverage numbers below are unaffected.
    }
  }, []);

  useEffect(() => {
    load();
    refreshJobs();
    // Read once: the narrator and the "is Vbee configured at all" flag do not
    // change under the page, and a failure here must not block the coverage
    // report — it only means the Vbee panel renders its unconfigured state.
    voiceoverService
      .getSettings()
      .then(setSettings)
      .catch(() => setSettings(null));
  }, [load, refreshJobs]);

  const globalJob = feed?.global ?? null;
  const courseJobs = feed?.courses ?? [];
  const globalRunning = globalJob?.status === "running";
  const runningCourseJobs = courseJobs.filter((job) => job.status === "running");
  const anyRunning = globalRunning || runningCourseJobs.length > 0;

  useEffect(() => {
    window.clearTimeout(pollRef.current);
    const delay = document.hidden
      ? POLL_HIDDEN_MS
      : anyRunning
      ? POLL_RUNNING_MS
      : POLL_IDLE_MS;
    pollRef.current = window.setTimeout(refreshJobs, delay);
    return () => window.clearTimeout(pollRef.current);
  }, [anyRunning, feed, refreshJobs]);

  // Announce completion once, on the running -> finished transition, and refresh
  // the coverage numbers that the run just changed.
  useEffect(() => {
    if (globalRunning) {
      wasRunningRef.current = true;
      return;
    }
    if (!wasRunningRef.current || !globalJob) return;
    wasRunningRef.current = false;

    if (globalJob.status === "failed") {
      showError(`Job lồng tiếng thất bại: ${globalJob.lastError || "lỗi không rõ"}`);
    } else if (globalJob.status === "interrupted") {
      showError("Job lồng tiếng bị ngắt giữa — bấm Chạy tiếp để tiếp tục.");
    } else {
      showSuccess(
        `Đã dub xong: ${globalJob.generated} tạo mới, ${globalJob.skipped} bỏ qua` +
          (globalJob.failed ? `, ${globalJob.failed} lỗi` : "")
      );
    }
    load();
  }, [globalRunning, globalJob, showError, showSuccess, load]);

  // Which badge each course row shows. The global run contributes the queued /
  // done / current split; a per-course run overrides it for its own row.
  const rowStates = useMemo(() => {
    const states = new Map<string, RowRunState>();

    if (globalJob?.status === "running") {
      globalJob.queuedCourseIds.forEach((id) => states.set(id, "queued"));
      globalJob.doneCourseIds.forEach((id) => states.set(id, "done"));
      if (globalJob.currentCourseId) {
        states.set(globalJob.currentCourseId, "running");
      }
    }

    for (const job of courseJobs) {
      if (job.status === "running") states.set(job.courseId, "running");
      else if (job.status === "done") states.set(job.courseId, "done");
      else if (job.status === "failed") states.set(job.courseId, "failed");
      else if (job.status === "interrupted") {
        states.set(job.courseId, "interrupted");
      }
    }

    return states;
  }, [globalJob, courseJobs]);

  const handleScan = () => {
    setLoading(true);
    load();
  };

  const startGlobal = async (
    kind: "needed" | "force" | "resume",
    force: boolean,
    resume: boolean,
    successMessage: string
  ) => {
    if (anyRunning || starting) return;
    setStarting(kind);
    try {
      await voiceoverService.generateAll(force, resume);
      showSuccess(successMessage);
      await refreshJobs();
    } catch (err: any) {
      showError(
        err?.response?.data?.message || "Failed to start voiceover batch"
      );
    } finally {
      setStarting(null);
    }
  };

  const handleGenerateNeeded = () =>
    startGlobal("needed", false, false, "Đã bắt đầu dub những bài còn thiếu ở nền…");

  const handleForceAll = () => {
    setConfirmForce(false);
    return startGlobal("force", true, false, "Đã bắt đầu force dub lại toàn bộ ở nền…");
  };

  // Continues an interrupted run in the mode it was started with, skipping the
  // courses it had already finished.
  const handleResume = () =>
    startGlobal(
      "resume",
      globalJob?.mode === "force",
      true,
      "Đang chạy tiếp job đã bị ngắt…"
    );

  // A Vbee course costs money to dub, so the first click only opens the
  // estimate. Everything else starts immediately, exactly as before.
  const handleRowDubClick = (course: CourseVoiceoverSummary) => {
    if (anyRunning || startingRows.has(course.courseId)) return;
    if (course.viProvider === "vbee") {
      setPendingDub({ course, switchToVbee: false });
      return;
    }
    void handleRowDub(course);
  };

  /**
   * "Dub Vbee" on a course still on Edge: one click instead of toggle-then-dub.
   *
   * It still PERSISTS the switch (after the confirm) rather than passing the
   * provider as a one-off. A provider that lived only in the request would be
   * undone by the next catalogue-wide run, which would re-dub the course back
   * to Edge and throw away audio that cost real credit.
   */
  const handleRowDubVbee = (course: CourseVoiceoverSummary) => {
    if (anyRunning || startingRows.has(course.courseId)) return;
    setPendingDub({ course, switchToVbee: course.viProvider !== "vbee" });
  };

  /**
   * Turn the paid provider on or off for one course.
   *
   * Nothing is re-dubbed here: the flag only changes which narrator the NEXT
   * run resolves for Vietnamese. That is also why the row's coverage flips to
   * `stale` afterwards — the stored narrator no longer matches.
   */
  const handleToggleProvider = async (
    course: CourseVoiceoverSummary,
    next: VoiceoverProviderKind
  ): Promise<boolean> => {
    if (togglingRows.has(course.courseId)) return false;
    setTogglingRows((prev) => new Set(prev).add(course.courseId));
    try {
      await voiceoverService.setCourseProvider(course.courseId, next);
      // Patch the row in place rather than re-scanning the whole catalogue —
      // a full scan reads every keypoint of every course.
      setStatus((prev) =>
        prev
          ? {
              ...prev,
              courses: prev.courses.map((row) =>
                row.courseId === course.courseId
                  ? { ...row, viProvider: next }
                  : row
              ),
            }
          : prev
      );
      showSuccess(
        next === "vbee"
          ? "Đã bật Vbee cho tiếng Việt của khoá này. Bấm Dub để áp dụng."
          : "Đã trả khoá này về giọng Edge miễn phí. Bấm Dub để áp dụng."
      );
      return true;
    } catch (err: any) {
      showError(
        err?.response?.data?.message || "Không đổi được nhà cung cấp giọng"
      );
      return false;
    } finally {
      setTogglingRows((prev) => {
        const nextSet = new Set(prev);
        nextSet.delete(course.courseId);
        return nextSet;
      });
    }
  };

  const handleRowDub = async (
    course: CourseVoiceoverSummary,
    force = false
  ) => {
    if (anyRunning || startingRows.has(course.courseId)) return;
    setStartingRows((prev) => new Set(prev).add(course.courseId));
    try {
      await voiceoverService.generateForCourse(course.courseId, force);
      showSuccess(
        `Đã bắt đầu dub cho "${getTranslationValue(course.title, lang) || course.courseId}"`
      );
      // Pull the feed straight away so the row's badge appears now rather than
      // at the next poll tick.
      await refreshJobs();
    } catch (err: any) {
      showError(
        err?.response?.data?.message || "Failed to start course voiceover"
      );
    } finally {
      setStartingRows((prev) => {
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

  const jobCourseName = (job: VoiceoverJob) =>
    getTranslationValue(job.currentCourseTitle, lang) ||
    job.currentCourseId ||
    "—";
  const jobKeypointName = (job: VoiceoverJob) =>
    getTranslationValue(job.currentKeypointTitle, lang) ||
    job.currentKeypointId ||
    "—";

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
              disabled={anyRunning || starting !== null}
              className="inline-flex items-center gap-2 rounded-lg bg-indigo-600 px-4 py-2 text-sm font-medium text-white shadow-sm transition hover:bg-indigo-700 disabled:opacity-60"
            >
              <Volume2Icon className="h-4 w-4" />
              {starting === "needed" ? "Đang bắt đầu…" : "Dub những cái cần"}
            </button>
            <button
              type="button"
              onClick={() => setConfirmForce(true)}
              disabled={anyRunning || starting !== null}
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

        {/* Vbee narrator. Rendered above the table because changing the voice
            changes what every Vbee row will cost on its next dub. */}
        <VbeeVoicePanel
          settings={settings}
          onSaved={setSettings}
          onSuccess={showSuccess}
          onError={showError}
        />

        {/* Running global job */}
        {globalJob && globalJob.status === "running" && (
          <div className="rounded-xl border border-indigo-200 bg-indigo-50 p-4 shadow-sm">
            <div className="flex flex-wrap items-center justify-between gap-2 text-sm text-indigo-800">
              <span className="flex items-center gap-2 font-medium">
                <Loader2Icon className="h-4 w-4 animate-spin" />
                Đang {globalJob.mode === "force" ? "force dub" : "dub"} ở nền…{" "}
                {globalJob.processedCourses}/{globalJob.totalCourses} course ·{" "}
                {globalJob.processed}/{globalJob.totalKeypoints} keypoint
              </span>
              <span className="text-xs text-indigo-500">
                {formatEta(globalJob.etaSeconds)
                  ? `còn ~${formatEta(globalJob.etaSeconds)}`
                  : "tự cập nhật mỗi 3s"}
              </span>
            </div>
            <div className="mt-2 h-2 w-full overflow-hidden rounded-full bg-indigo-100">
              <div
                className="h-full rounded-full bg-indigo-500 transition-all"
                style={{
                  width: `${
                    globalJob.totalKeypoints
                      ? (globalJob.processed / globalJob.totalKeypoints) * 100
                      : 0
                  }%`,
                }}
              />
            </div>
            <dl className="mt-3 grid gap-x-6 gap-y-1 text-xs text-indigo-700 sm:grid-cols-2">
              <div className="flex gap-1 truncate">
                <dt className="text-indigo-500">Course:</dt>
                <dd className="truncate font-medium" title={jobCourseName(globalJob)}>
                  {jobCourseName(globalJob)}
                </dd>
              </div>
              <div className="flex gap-1 truncate">
                <dt className="text-indigo-500">Keypoint:</dt>
                <dd className="truncate font-medium" title={jobKeypointName(globalJob)}>
                  {jobKeypointName(globalJob)}
                </dd>
              </div>
            </dl>
            <div className="mt-2 flex flex-wrap gap-x-4 gap-y-1 text-xs text-indigo-700">
              <span>Đã tạo: {globalJob.generated}</span>
              <span>Bỏ qua: {globalJob.skipped}</span>
              <span>Lỗi: {globalJob.failed}</span>
            </div>
          </div>
        )}

        {/* Per-course runs, when there is no global run to fold them into */}
        {!globalRunning && runningCourseJobs.length > 0 && (
          <div className="rounded-xl border border-indigo-200 bg-indigo-50 p-4 text-sm text-indigo-800 shadow-sm">
            {runningCourseJobs.map((job) => (
              <div key={job.courseId} className="flex flex-wrap items-center gap-2">
                <Loader2Icon className="h-4 w-4 animate-spin" />
                <span className="font-medium">Đang dub {jobCourseName(job)}</span>
                <span className="text-xs text-indigo-600">
                  {job.processed}/{job.totalKeypoints} keypoint · keypoint hiện tại:{" "}
                  {jobKeypointName(job)}
                  {formatEta(job.etaSeconds) ? ` · còn ~${formatEta(job.etaSeconds)}` : ""}
                </span>
              </div>
            ))}
          </div>
        )}

        {/* Interrupted global job — the run's process died (deploy/restart) */}
        {globalJob && globalJob.status === "interrupted" && (
          <div className="flex flex-col gap-3 rounded-xl border border-amber-300 bg-amber-50 p-4 text-sm text-amber-900 shadow-sm sm:flex-row sm:items-center sm:justify-between">
            <span className="flex items-start gap-2">
              <AlertTriangleIcon className="mt-0.5 h-5 w-5 flex-none text-amber-600" />
              <span>
                Job lồng tiếng bị ngắt giữa (deploy/restart) sau{" "}
                {globalJob.processedCourses}/{globalJob.totalCourses} course.
                Những course đã xong sẽ được bỏ qua khi chạy tiếp.
              </span>
            </span>
            <button
              type="button"
              onClick={handleResume}
              disabled={starting !== null}
              className="inline-flex shrink-0 items-center gap-2 rounded-lg bg-amber-600 px-4 py-2 text-sm font-semibold text-white shadow-sm transition hover:bg-amber-700 disabled:opacity-60"
            >
              <PlayIcon className="h-4 w-4" />
              {starting === "resume" ? "Đang bắt đầu…" : "Chạy tiếp"}
            </button>
          </div>
        )}

        {globalJob && globalJob.status === "failed" && (
          <div className="flex items-start gap-2 rounded-lg border border-red-200 bg-red-50 px-4 py-3 text-sm text-red-700 shadow-sm">
            <AlertTriangleIcon className="mt-0.5 h-5 w-5 flex-none" />
            Job lồng tiếng lần trước thất bại: {globalJob.lastError || "lỗi không rõ"}
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

        {/* Why the failed cells failed. Without this, a count can't tell an
            endpoint refusing calls now from stale errors left by a TTS provider
            that has since been swapped out. */}
        {(status?.topErrors?.length ?? 0) > 0 && (
          <div className="rounded-xl border border-red-200 bg-white p-4 shadow-sm">
            <h2 className="flex items-center gap-2 text-sm font-semibold text-slate-900">
              <AlertTriangleIcon className="h-4 w-4 text-red-500" />
              Lỗi thường gặp nhất
            </h2>
            <ul className="mt-2 space-y-1">
              {status?.topErrors.map((tally) => (
                <li
                  key={tally.message}
                  className="flex items-start justify-between gap-3 text-xs text-slate-600"
                >
                  <span className="break-all">{tally.message}</span>
                  <span className="shrink-0 rounded-full bg-red-100 px-2 py-0.5 font-semibold text-red-700">
                    {tally.count} ô
                  </span>
                </li>
              ))}
            </ul>
          </div>
        )}

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
                    <th className="px-4 py-3 font-medium">Tiến trình</th>
                    <th className="px-4 py-3 font-medium">Độ phủ</th>
                    <th className="px-4 py-3 font-medium">Giọng vi</th>
                    <th className="px-4 py-3 text-right font-medium">Hành động</th>
                  </tr>
                </thead>
                <tbody className="divide-y divide-slate-100">
                  {filteredCourses.map((course) => {
                    const title = getTranslationValue(course.title, lang) || course.courseId;
                    const rowState = rowStates.get(course.courseId);
                    const badge = rowState ? ROW_BADGE[rowState] : null;
                    const rowStarting = startingRows.has(course.courseId);
                    const isCurrent = rowState === "running";
                    // Whichever run is dubbing this row — the global one when it
                    // is on this course, otherwise the row's own job.
                    const rowJob = isCurrent
                      ? globalRunning && globalJob?.currentCourseId === course.courseId
                        ? globalJob
                        : courseJobs.find((j) => j.courseId === course.courseId)
                      : undefined;
                    return (
                      <tr
                        key={course.courseId}
                        className={`align-top ${
                          isCurrent ? "bg-indigo-50/60" : "hover:bg-indigo-50/30"
                        }`}
                      >
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
                          {badge ? (
                            <span
                              className={`inline-flex items-center gap-1 rounded-full px-2 py-0.5 text-xs font-semibold ${badge.className}`}
                            >
                              {badge.spinning ? (
                                <Loader2Icon className="h-3 w-3 animate-spin" />
                              ) : rowState === "queued" ? (
                                <ClockIcon className="h-3 w-3" />
                              ) : rowState === "done" ? (
                                <CheckCircle2Icon className="h-3 w-3" />
                              ) : (
                                <AlertTriangleIcon className="h-3 w-3" />
                              )}
                              {badge.label}
                            </span>
                          ) : (
                            <span className="text-xs text-slate-300">—</span>
                          )}
                          {rowJob && (
                            <p
                              className="mt-1 max-w-[14rem] truncate text-[11px] text-indigo-600"
                              title={jobKeypointName(rowJob)}
                            >
                              {jobKeypointName(rowJob)}
                            </p>
                          )}
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
                        <td className="px-4 py-3">
                          {/* Vietnamese only. The other four locales have no
                              paid option, so there is nothing to choose. */}
                          <button
                            type="button"
                            onClick={() =>
                              handleToggleProvider(
                                course,
                                course.viProvider === "vbee" ? "edge" : "vbee"
                              )
                            }
                            disabled={
                              !settings?.vbeeConfigured ||
                              anyRunning ||
                              togglingRows.has(course.courseId)
                            }
                            title={
                              !settings?.vbeeConfigured
                                ? "Vbee chưa được cấu hình trên môi trường này"
                                : course.viProvider === "vbee"
                                ? "Đang dùng Vbee (tốn điểm) — bấm để trả về Edge"
                                : "Đang dùng Edge (miễn phí) — bấm để chuyển sang Vbee"
                            }
                            className={`inline-flex items-center gap-1 rounded-full px-2.5 py-0.5 text-xs font-semibold disabled:cursor-not-allowed disabled:opacity-50 ${
                              course.viProvider === "vbee"
                                ? "bg-purple-100 text-purple-700 hover:bg-purple-200"
                                : "bg-slate-100 text-slate-600 hover:bg-slate-200"
                            }`}
                          >
                            {togglingRows.has(course.courseId) && (
                              <Loader2Icon className="h-3 w-3 animate-spin" />
                            )}
                            {course.viProvider === "vbee" ? "Vbee" : "Edge"}
                          </button>
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
                              onClick={() => handleRowDubClick(course)}
                              disabled={anyRunning || rowStarting}
                              className="inline-flex items-center gap-1 rounded-md bg-indigo-600 px-2.5 py-1 text-xs font-medium text-white hover:bg-indigo-700 disabled:opacity-50"
                            >
                              {rowStarting ? (
                                <Loader2Icon className="h-3.5 w-3.5 animate-spin" />
                              ) : (
                                <Volume2Icon className="h-3.5 w-3.5" />
                              )}
                              Dub
                            </button>
                            {/* Shortcut for the common flow: nominate this
                                course for the paid voice and dub it, without
                                first hunting for the toggle. Hidden once the
                                course is already on Vbee — plain Dub does it. */}
                            {settings?.vbeeConfigured &&
                              course.viProvider !== "vbee" && (
                                <button
                                  type="button"
                                  onClick={() => handleRowDubVbee(course)}
                                  disabled={anyRunning || rowStarting}
                                  title="Chuyển khoá này sang Vbee rồi dub — sẽ hiện chi phí trước"
                                  className="inline-flex items-center gap-1 rounded-md bg-purple-600 px-2.5 py-1 text-xs font-medium text-white hover:bg-purple-700 disabled:opacity-50"
                                >
                                  <Volume2Icon className="h-3.5 w-3.5" />
                                  Dub Vbee
                                </button>
                              )}
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

      {/* Vbee dub cost confirmation */}
      {pendingDub && (
        <VbeeDubConfirmDialog
          courseId={pendingDub.course.courseId}
          courseTitle={
            getTranslationValue(pendingDub.course.title, lang) ||
            pendingDub.course.courseId
          }
          switchingToVbee={pendingDub.switchToVbee}
          onCancel={() => setPendingDub(null)}
          onConfirm={async (force) => {
            const { course, switchToVbee } = pendingDub;
            setPendingDub(null);
            // Persist first, then dub: the run reads the course's stored
            // provider, so dubbing before the write would still use Edge.
            if (switchToVbee) {
              const ok = await handleToggleProvider(course, "vbee");
              if (!ok) return;
            }
            void handleRowDub(course, force);
          }}
        />
      )}

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
