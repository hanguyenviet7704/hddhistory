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
};
