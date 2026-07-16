import axiosClient from "./axiosClient";

// TTS voiceover generation (edge-tts, server-side). Audio is generated from a
// keypoint's theory content and stored on keypoint.audio.url — the manual
// audio fields are gone, this is the only way audio is produced now.
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
  async getGlobalStatus() {
    const res = await axiosClient.get("/voiceover/status");
    return res.data;
  },

  // Kick off a background job over every course. force=false only (re)dubs
  // missing/stale/failed cells; force=true regenerates everything.
  async generateAll(force: boolean) {
    const res = await axiosClient.post(
      `/voiceover/generate-all?force=${force}`
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
