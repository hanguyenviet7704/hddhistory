import {
  CoachConfig,
  CoachSituationVariant,
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
  async getSituations(params?: {
    habitId?: string;
    locale?: string;
    variant?: CoachSituationVariant;
  }) {
    const res = await axiosClient.get("/coach-situations", { params });
    return res.data;
  },

  async updateSituation(id: string, prompt: string) {
    const res = await axiosClient.put(`/coach-situations/${id}`, { prompt });
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
};
