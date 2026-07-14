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
