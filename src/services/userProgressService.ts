import {
  RemoveUserProgress,
  UserProgressListQuery,
} from "../types/interface/user-progress.interface";
import axiosClient from "./axiosClient";

export const userProgressService = {
  async getList(params?: Partial<UserProgressListQuery>) {
    const res = await axiosClient.get("/courses-user-progress", { params });
    return res.data;
  },

  async remove(params?: Partial<RemoveUserProgress>) {
    return axiosClient.delete(`/courses-user-progress`, { params });
  },
};
