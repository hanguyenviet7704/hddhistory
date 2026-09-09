import axiosClient from "./axiosClient";
import unwrapApi from "../utils/unwrapApi";

// TTS voiceover generation (free Microsoft Edge neural voices, server-side — no
// key, no per-character billing). One clip per CARD (theory pages read in full, exercise cards read
// the QUESTION only) plus one whole-keypoint file for app builds released before
// per-card narration. Stored on keypoint.audio; the manual audio fields are gone,
// this is the only way audio is produced now.
//
// The narrator is fixed server-side at one female voice per language, so none of
// these calls sends a body. The old per-language picker (and its
// `GET /voiceover/voices` feed) is gone: a keypoint's stored narrator used to be
// reused on every re-dub, which quietly kept old male-voiced keypoints male
// forever.
export const voiceoverService = {
  async generateForKeypoint(keypointId: string) {
    const res = await axiosClient.post(`/voiceover/keypoint/${keypointId}`);
    return res.data;
  },

  async generateForCourse(courseId: string) {
    const res = await axiosClient.post(`/voiceover/course/${courseId}`);
    return res.data;
  },

  // Read-only coverage report: which keypoints × languages are done / stale /
  // missing / failed.
  async getCourseStatus(courseId: string) {
    const res = await axiosClient.get(`/voiceover/course/${courseId}/status`);
    return res.data;
  },

  // Global coverage report across every course, plus the running/last
  // global batch job (if any). Backs the /voiceover batch management page.
  //
  // This scans the whole catalogue, so it is the "Quét" action — NOT the
  // progress poll. Poll `getJobs` instead.
  async getGlobalStatus() {
    const res = await axiosClient.get("/voiceover/status");
    return res.data;
  },

  // Progress of every dub run in flight (the global one and any per-course
  // ones), and nothing else — one document per run, cheap enough to poll every
  // few seconds while a job works.
  async getJobs() {
    const res = await axiosClient.get("/voiceover/job");
    return res.data;
  },

  // Kick off a background job over every course. force=false only (re)dubs
  // missing/stale/failed cells; force=true regenerates everything. resume=true
  // continues an interrupted run, skipping the courses it had already finished.
  async generateAll(force: boolean, resume = false) {
    const res = await axiosClient.post(
      `/voiceover/generate-all?force=${force}&resume=${resume}`
    );
    return res.data;
  },

  // --- Vbee (paid Vietnamese provider) --------------------------------------
  //
  // Vietnamese only, and only on courses explicitly switched over: Vbee bills
  // per character, so nothing here may become a catalogue-wide default.

  // Every Vietnamese voice the account can use, with its credit factor and a
  // demo clip. `creditFactor` is the difference between a run costing X and 3X,
  // so the picker shows it next to the name rather than hiding it.
  async getVbeeVoices(): Promise<VbeeVoice[]> {
    const res = await axiosClient.get("/voiceover/vbee/voices");
    return unwrapApi<VbeeVoice[]>(res.data) ?? [];
  },

  async getSettings(): Promise<VoiceoverSettings> {
    const res = await axiosClient.get("/voiceover/settings");
    return unwrapApi<VoiceoverSettings>(res.data);
  },

  async updateVbeeVoice(vbeeVoiceCode: string): Promise<VoiceoverSettings> {
    const res = await axiosClient.put("/voiceover/settings", { vbeeVoiceCode });
    return unwrapApi<VoiceoverSettings>(res.data);
  },

  // Opt one course's Vietnamese in or out. Changes nothing on its own — the
  // next dub of that course is what re-synthesises Vietnamese.
  async setCourseProvider(courseId: string, provider: VoiceoverProviderKind) {
    const res = await axiosClient.put(`/voiceover/course/${courseId}/provider`, {
      provider,
    });
    return unwrapApi(res.data);
  },

  // Characters (and credits) the next Vbee dub of this course would spend.
  // Counted from the same reuse rules the dub uses, not averaged.
  async estimateCourse(courseId: string): Promise<CourseVoiceoverEstimate> {
    const res = await axiosClient.get(`/voiceover/course/${courseId}/estimate`);
    return unwrapApi<CourseVoiceoverEstimate>(res.data);
  },
};

/** Which speech engine dubs a course's Vietnamese. Other locales are always Edge. */
export type VoiceoverProviderKind = "edge" | "vbee";

export interface VbeeVoice {
  code: string;
  name: string;
  gender: string;
  languageCode: string;
  /** Characters billed per character read: 1 standard, 2 "nâng cao", 3 "2.0". */
  creditFactor: number;
  demo: string;
}

export interface VoiceoverSettings {
  vbeeVoiceCode: string;
  /** False when the environment has no Vbee credentials — the toggle stays off. */
  vbeeConfigured: boolean;
}

export interface CourseVoiceoverEstimate {
  courseId: string;
  provider: VoiceoverProviderKind;
  keypoints: number;
  /** What the NEXT run would synthesise, after per-card reuse. */
  chars: number;
  /** Every Vietnamese character in the course — the cost of a forced re-dub. */
  charsIfForced: number;
  voiceCode: string;
  creditFactor: number;
  estimatedCredits: number;
  /** 0 when uncapped. */
  maxCharsPerRun: number;
}

export type VoiceoverCellStatus =
  | "done"
  | "stale"
  | "missing"
  | "failed"
  | "none";

export interface KeypointVoiceoverStatus {
  keypointId: string;
  title: Record<string, string>;
  statuses: Record<string, VoiceoverCellStatus>;
  errors?: Record<string, string>;
}

// `interrupted` is not a status the server stores — it derives it when a job
// left `running` stops writing heartbeats, which is what a deploy or restart
// mid-dub looks like. Treat it as "not running, resumable", never as progress.
export type VoiceoverJobStatus =
  | "running"
  | "done"
  | "failed"
  | "interrupted";

// One dub run. `scope` is "global" for the catalogue-wide job and "course" for a
// single row's Dub, and both come back from the same poll — a per-course run used
// to be invisible to this page.
export interface VoiceoverJob {
  scope: "global" | "course";
  courseId: string;
  status: VoiceoverJobStatus;
  mode: "needed" | "force";
  totalCourses: number;
  processedCourses: number;
  totalKeypoints: number;
  processed: number;
  generated: number;
  skipped: number;
  failed: number;
  currentCourseId: string;
  currentCourseTitle: Record<string, string>;
  currentKeypointId: string;
  currentKeypointTitle: Record<string, string>;
  // Courses this run has yet to reach / has finished — the per-row
  // "Đang chờ" / "Xong" badges.
  queuedCourseIds: string[];
  doneCourseIds: string[];
  lastError: string;
  startedAt: number;
  finishedAt?: number;
  heartbeatAt: number;
  // Seconds left at the pace measured so far; null before there is a pace.
  etaSeconds: number | null;
}

export interface VoiceoverJobFeed {
  global: VoiceoverJob | null;
  courses: VoiceoverJob[];
}

export interface CourseVoiceoverStatus {
  courseId: string;
  langs: string[];
  summary: Record<VoiceoverCellStatus, number>;
  keypoints: KeypointVoiceoverStatus[];
  job?: VoiceoverJob | null;
}

// --- Global (all-courses) batch status -------------------------------------

export interface CourseVoiceoverSummary {
  courseId: string;
  title: Record<string, string> | string;
  keypointCount: number;
  summary: Record<VoiceoverCellStatus, number>;
  /** Which engine dubs this course's Vietnamese; absent on older API builds. */
  viProvider?: VoiceoverProviderKind;
}

// One distinct failure message and how many cells carry it. A bare "1190 failed"
// can't tell an endpoint refusing calls right now from stale errors left by a TTS
// provider that has since been swapped out.
export interface VoiceoverErrorTally {
  message: string;
  count: number;
}

export interface GlobalVoiceoverStatus {
  langs: string[];
  summary: Record<VoiceoverCellStatus, number> & { total: number };
  courses: CourseVoiceoverSummary[];
  topErrors: VoiceoverErrorTally[];
  job: VoiceoverJob | null;
}
