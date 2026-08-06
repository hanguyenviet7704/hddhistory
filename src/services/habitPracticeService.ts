import {
  HabitPracticePayload,
  HabitPracticeUpdatePayload,
  IHabitPractice,
  IPracticeLearningItem,
} from "../types/interface/habitPractice.interface";
import axiosClient from "./axiosClient";

/**
 * `GET /courses-learning-items` builds its search filter with an UNESCAPED
 * `new RegExp(search, 'i')`, so a stray `(` or `[` from the picker's search box
 * would come back as a 500. Escape here rather than patching that shared
 * endpoint: it also makes the search literal, which is what a content editor
 * typing a title actually wants.
 */
const escapeRegex = (value: string) =>
  value.replace(/[.*+?^${}()|[\]\\]/g, "\\$&");

export const habitPracticeService = {
  /** Practices on a habit, every status, content hydrated. Admin-only route. */
  async list(habitId: string): Promise<IHabitPractice[]> {
    const res = await axiosClient.get("/habit-practices/admin", {
      params: { habitId },
    });
    return res.data?.data ?? res.data ?? [];
  },

  async create(payload: HabitPracticePayload) {
    const res = await axiosClient.post("/habit-practices/admin", payload);
    return res.data?.data ?? res.data;
  },

  async update(id: string, payload: HabitPracticeUpdatePayload) {
    const res = await axiosClient.patch(`/habit-practices/admin/${id}`, payload);
    return res.data?.data ?? res.data;
  },

  async remove(id: string) {
    const res = await axiosClient.delete(`/habit-practices/admin/${id}`);
    return res.data?.data ?? res.data;
  },

  /**
   * Candidate content to attach. Reuses the existing learning-item list, which
   * omits its `keypointId` filter when none is passed — so habit-owned items
   * (authored without a keypoint) show up alongside keypoint exercises.
   */
  async searchLearningItems(params: {
    type: string;
    search?: string;
    page?: number;
    take?: number;
  }): Promise<{ items: IPracticeLearningItem[]; totalPages: number }> {
    const res = await axiosClient.get("/courses-learning-items", {
      params: {
        page: params.page ?? 1,
        take: params.take ?? 20,
        type: params.type,
        ...(params.search?.trim()
          ? { search: escapeRegex(params.search.trim()) }
          : {}),
      },
    });
    const data = res.data?.data ?? res.data ?? {};
    return { items: data.items ?? [], totalPages: data.totalPages ?? 1 };
  },
};
