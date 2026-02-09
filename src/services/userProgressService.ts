import {
  ExportAllUserProgressResponse,
  ICourseLearningStatistics,
  ProgressOfUserQuery,
  RemoveUserProgress,
  StatisticsUsersLearningCoursesQuery,
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
    params?: Partial<ProgressOfUserQuery>,
  ) {
    const res = await axiosClient.get(
      `/courses-user-progress/users/${userId}`,
      { params },
    );
    return res.data;
  },

  async getCourseProgressDetailOfUser(userId: string, courseId: string) {
    const res = await axiosClient.get(
      `/courses-user-progress/users/${userId}/courses/${courseId}`,
    );
    return res.data;
  },

  async exportAllUserProgress(): Promise<ExportAllUserProgressResponse> {
    const res = await axiosClient.post(`/courses-user-progress/export`);
    return res.data;
  },

  async statisticsUsersLearningCourses(
    params: StatisticsUsersLearningCoursesQuery,
  ): Promise<ICourseLearningStatistics[]> {
    const res = await axiosClient.get(
      `/courses-user-progress/statistics-users-learning-courses`,
      { params },
    );
    return res.data;
  },
};
