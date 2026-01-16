import {
  ProgressOfUserQuery,
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

  async getProgressOfUser(
    userId: string,
    params?: Partial<ProgressOfUserQuery>
  ) {
    const res = await axiosClient.get(
      `/courses-user-progress/users/${userId}`,
      { params }
    );
    return res.data;
  },

  async getCourseProgressDetailOfUser(userId: string, courseId: string) {
    const res = await axiosClient.get(
      `/courses-user-progress/users/${userId}/courses/${courseId}`
    );
    return res.data;
  },
};
