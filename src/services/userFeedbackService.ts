import {
  IUserFeedback,
  IUserFeedbackCommentPage,
  IUserFeedbackStatisticsOverview,
  IUserFeedbackStatisticsQuery,
} from "../types/interface/user-feedback.interface";
import axiosClient from "./axiosClient";

export const userFeedbackService = {
  async getByUserId(id: string): Promise<IUserFeedback> {
    const res = await axiosClient.get(`/courses-feedback/${id}`, {});
    return res.data;
  },

  async remove(id: string) {
    return axiosClient.delete(`/courses-feedback/${id}`, {});
  },

  async getStatisticsOverview(
    params: IUserFeedbackStatisticsQuery
  ): Promise<IUserFeedbackStatisticsOverview> {
    const res = await axiosClient.get("/courses-feedback/statistics/overview", {
      params,
    });
    return res.data;
  },

  async getStatisticsComments(
    params: IUserFeedbackStatisticsQuery & { page?: number; take?: number }
  ): Promise<IUserFeedbackCommentPage> {
    const res = await axiosClient.get("/courses-feedback/statistics/comments", {
      params,
    });
    return res.data;
  },
};
