import axiosClient from "./axiosClient";
import { unwrapApi } from "../utils/unwrapApi";

export interface ExperimentArm {
  courseId: string;
  tagA: string;
  tagB: string;
}

export interface ContentExperiment {
  _id: string;
  key: string;
  enabled: boolean;
  percentB: number;
  startedAt: string;
  endedAt?: string | null;
  arms: ExperimentArm[];
  note?: string | null;
  createdAt?: string;
  createdBy?: { email?: string } | null;
}

export interface ContentExperimentArmStats {
  arm: "A" | "B";
  viewers: number;
  keypointStarts: number;
  exercises: number;
  completes: number;
  skips: number;
  exits: number;
  reports: number;
  completionRate: number;
}

export interface ContentExperimentStats {
  key: string;
  enabled: boolean;
  percentB: number;
  startedAt: string;
  endedAt?: string | null;
  arms: ContentExperimentArmStats[];
}

/**
 * A/B nội dung khoá học. Hai tag của cùng một khoá làm hai nhánh; chia người
 * bằng hash(key + userId) nên không có bảng gán nhánh và `key` phải đổi mỗi đợt.
 * Xem `meup-api/plans/260908-course-content-ab-test/README.md`.
 */
export const contentExperimentService = {
  async list() {
    const res = await axiosClient.get("/course-content-experiments");
    return unwrapApi<ContentExperiment[]>(res.data);
  },

  async create(payload: {
    key: string;
    percentB: number;
    startedAt: string;
    arms: ExperimentArm[];
    note?: string;
  }) {
    const res = await axiosClient.post("/course-content-experiments", payload);
    return unwrapApi<ContentExperiment>(res.data);
  },

  async setEnabled(id: string, enabled: boolean) {
    const res = await axiosClient.put(
      `/course-content-experiments/${id}/enabled`,
      { enabled }
    );
    return unwrapApi<ContentExperiment>(res.data);
  },

  async stats(key: string, env: string) {
    const res = await axiosClient.get(
      `/course-content-experiments/${key}/stats`,
      { params: { env } }
    );
    return unwrapApi<ContentExperimentStats>(res.data);
  },
};

export default contentExperimentService;
