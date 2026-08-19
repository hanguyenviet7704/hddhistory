import {
  ExportAllUserProgressResponse,
  ICourseLearningStatistics,
  ProgressOfUserQuery,
  RemoveUserProgress,
  StatisticsUsersLearningCoursesQuery,
  UserProgressListQuery,
  ICourseDropOff,
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

  /**
   * Histogram điểm dừng của MỘT khoá học, gộp trên toàn bộ user — đọc từ
   * `user_progress.stopAt` phía server, không phải từ event nào của app, nên
   * phủ mọi user từ trước tới nay và không có TTL.
   */
  async getCourseDropOff(params: {
    courseId: string;
    /** Số ngày không hoạt động để tính là "dừng hẳn". 0 = đếm tất cả. */
    staleDays?: number;
  }): Promise<ICourseDropOff> {
    const res = await axiosClient.get(`/courses-user-progress/drop-off`, {
      params,
    });
    return res.data?.data ?? res.data;
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
