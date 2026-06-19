import axiosClient from "./axiosClient";

export interface IGetReportsQuery {
  page?: number;
  take?: number;
  lessonId?: string;
  courseId?: string;
  userId?: string;
  search?: string;
  orderBy?: string;
  order?: string;
}

export const reportService = {
  async getList(params: IGetReportsQuery) {
    return axiosClient.get("/courses-reports", { params });
  },

  async getById(id: string) {
    return axiosClient.get(`/courses-reports/${id}`);
  },

  async remove(id: string) {
    return axiosClient.delete(`/courses-reports/${id}`);
  },
};
