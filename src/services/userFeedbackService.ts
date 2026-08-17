import {
  IUserFeedback,
  IUserFeedbackCommentPage,
  IUserFeedbackStatisticsOverview,
  IUserFeedbackStatisticsQuery,
} from "../types/interface/user-feedback.interface";
import axiosClient from "./axiosClient";

// The response interceptor hands back the raw axios response, so `res.data` is
// the API envelope `{ statusCode, message, data }` — every other service in
// here unwraps it the same way. Skipping this is what turned the analytics page
// white: the component got the envelope and blew up on `reasonDistribution.length`.
const unwrapData = <T,>(payload: any): T => payload?.data ?? payload;

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
    return unwrapData<IUserFeedbackStatisticsOverview>(res.data);
  },

  async getStatisticsComments(
    params: IUserFeedbackStatisticsQuery & { page?: number; take?: number }
  ): Promise<IUserFeedbackCommentPage> {
    const res = await axiosClient.get("/courses-feedback/statistics/comments", {
      params,
    });
    return unwrapData<IUserFeedbackCommentPage>(res.data);
  },
};
