import axiosClient from "./axiosClient";

/// One narrator Google offers for a language, as returned by
/// GET /voiceover/voices.
export interface VoiceoverVoiceOption {
  /// Full Google voice name, e.g. `zh-CN-Chirp3-HD-Achernar`.
  name: string;
  /// Trailing speaker segment, e.g. `Achernar` — what the picker shows.
  speaker: string;
  gender: string;
}

/// Narrator per language code, e.g. `{ zh: "zh-CN-Chirp3-HD-Achernar" }`.
///
/// Per language, not one narrator for the whole run: failures are per language,
/// so Chinese erroring must be fixable without re-dubbing the other four. A
/// language left out keeps whatever narrator it was last dubbed with.
export type VoiceoverVoiceSelection = Record<string, string>;

// TTS voiceover generation (Google Cloud Chirp3-HD, server-side — billed per
// character). One clip per CARD (theory pages read in full, exercise cards read
// the QUESTION only) plus one whole-keypoint file for app builds released before
// per-card narration. Stored on keypoint.audio; the manual audio fields are gone,
// this is the only way audio is produced now.
export const voiceoverService = {
  // Narrators available per language, straight from Google's catalogue. The
  // list is NOT hardcoded client-side on purpose: a name invented here is how
  // every Chinese keypoint once failed with "Voice does not exist".
  async getVoiceOptions() {
    const res = await axiosClient.get<Record<string, VoiceoverVoiceOption[]>>(
      "/voiceover/voices"
    );
    return res.data;
  },

  async generateForKeypoint(
    keypointId: string,
    voices?: VoiceoverVoiceSelection
  ) {
    const res = await axiosClient.post(`/voiceover/keypoint/${keypointId}`, {
      voices,
    });
    return res.data;
  },

  async generateForCourse(courseId: string, voices?: VoiceoverVoiceSelection) {
    const res = await axiosClient.post(`/voiceover/course/${courseId}`, {
      voices,
    });
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
  async getGlobalStatus() {
    const res = await axiosClient.get("/voiceover/status");
    return res.data;
  },

  // Kick off a background job over every course. force=false only (re)dubs
  // missing/stale/failed cells; force=true regenerates everything.
  async generateAll(force: boolean, voices?: VoiceoverVoiceSelection) {
    const res = await axiosClient.post(
      `/voiceover/generate-all?force=${force}`,
      { voices }
    );
    return res.data;
  },
};

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

export interface VoiceoverJob {
  status: "running" | "done" | "failed";
  total: number;
  processed: number;
  generated: number;
  skipped: number;
  failed: number;
  currentKeypointId?: string;
  lastError?: string;
}

export interface CourseVoiceoverStatus {
  courseId: string;
  langs: string[];
  summary: Record<VoiceoverCellStatus, number>;
  keypoints: KeypointVoiceoverStatus[];
  job?: VoiceoverJob | null;
}

// --- Global (all-courses) batch status -------------------------------------

export interface GlobalVoiceoverJob {
  status: "running" | "done" | "failed";
  mode: "needed" | "force";
  totalCourses: number;
  processedCourses: number;
  currentCourseId: string | null;
  totalKeypoints: number;
  processed: number;
  generated: number;
  skipped: number;
  failed: number;
  lastError: string | null;
  startedAt: string;
}

export interface CourseVoiceoverSummary {
  courseId: string;
  title: Record<string, string> | string;
  keypointCount: number;
  summary: Record<VoiceoverCellStatus, number>;
}

export interface GlobalVoiceoverStatus {
  langs: string[];
  summary: Record<VoiceoverCellStatus, number> & { total: number };
  courses: CourseVoiceoverSummary[];
  job: GlobalVoiceoverJob | null;
}
