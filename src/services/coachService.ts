import {
  CoachConfig,
  CoachSituationUpdate,
  CoachSituationVariant,
  CoachContentKind,
} from "../types/interface/coach.interface";
import axiosClient from "./axiosClient";

export const coachService = {
  // ---- config (master switch + crisis lines) ----
  async getConfig() {
    const res = await axiosClient.get("/coach-config");
    return res.data;
  },

  async updateConfig(payload: Partial<CoachConfig>) {
    const res = await axiosClient.put("/coach-config", payload);
    return res.data;
  },

  // ---- cached situations ----
  // No create: rows appear when a reader first needs one. This surface exists
  // to fix or discard, not to author.
  /** Drop every AI-generated scene of one habit so its pool is rebuilt from the current description/contexts. Hand-edited scenes stay. */
  async rebuildHabitPool(habitId: string) {
    const res = await axiosClient.delete(`/coach-situations/habit/${habitId}`);
    return res.data;
  },

  async getSituations(params?: {
    habitId?: string;
    locale?: string;
    variant?: CoachSituationVariant;
  }) {
    const res = await axiosClient.get("/coach-situations", { params });
    return res.data;
  },

  /** Save a scene and its script. Any change flips the row to EDITED so generation never overwrites it. */
  async updateSituation(id: string, payload: CoachSituationUpdate) {
    const res = await axiosClient.put(`/coach-situations/${id}`, payload);
    return res.data;
  },

  async removeSituation(id: string) {
    const res = await axiosClient.delete(`/coach-situations/${id}`);
    return res.data;
  },

  // ---- the thumb-down queue ----
  async getRatings(params?: { needsReview?: boolean }) {
    const res = await axiosClient.get("/coach-ratings", { params });
    return res.data;
  },

  async markRatingReviewed(id: string) {
    const res = await axiosClient.put(`/coach-ratings/${id}/reviewed`);
    return res.data;
  },

  /**
   * Chữ do user tự viết.
   *
   * KHÔNG có hội thoại đầy đủ: lời Coach nói chỉ nằm trong phiên và Mongo xoá
   * phiên sau 48h. Riêng dòng trả lời tình huống có kèm `meta.situationPrompt`
   * — câu hỏi do biên tập viên viết nên còn lâu dài, và nó là thứ làm dòng
   * thời gian đọc được như một lượt qua lại.
   */
  async getContents(params?: {
    userId?: string;
    habitId?: string;
    kinds?: CoachContentKind[];
    from?: string;
    to?: string;
    search?: string;
    limit?: number;
  }) {
    const res = await axiosClient.get("/coach-contents", { params });
    return res.data;
  },

  /**
   * Xoá hẳn một dòng nội dung. Không hoàn tác được.
   *
   * `kind` không thừa: sáu loại nằm ở bốn nguồn khác nhau, server phải biết
   * loại mới biết xoá ở đâu — và với ba loại chung một collection, nó còn là
   * cái chặn xoá nhầm dòng khi id đúng mà loại sai. Riêng `dip` id mang hậu tố
   * `:dip`, cứ gửi nguyên như feed trả về.
   */
  async deleteContent(kind: CoachContentKind, id: string) {
    const res = await axiosClient.delete(
      `/coach-contents/${kind}/${encodeURIComponent(id)}`,
    );
    return res.data;
  },

  /** Ai có viết, viết bao nhiêu, lần cuối là khi nào — mới nhất lên đầu. */
  async getContentUsers(params?: {
    habitId?: string;
    kinds?: CoachContentKind[];
    from?: string;
    to?: string;
    search?: string;
    limit?: number;
  }) {
    const res = await axiosClient.get("/coach-contents/users", { params });
    return res.data;
  },

  /**
   * Toàn bộ lịch sử Coach của một user, đã dựng sẵn thành hội thoại.
   *
   * Mỗi phiên kèm `source`: `transcript` là nguyên văn, `derived` là tái dựng
   * vì phiên đã hết hạn lưu.
   */
  async getUserThread(
    userId: string,
    params?: { from?: string; to?: string; limit?: number },
  ) {
    const res = await axiosClient.get(`/coach-contents/users/${userId}/thread`, {
      params,
    });
    return res.data;
  },

  async getAiUsageSummary(params?: { from?: string; to?: string }) {
    const res = await axiosClient.get("/coach-ai-usage/summary", { params });
    return res.data;
  },
};
