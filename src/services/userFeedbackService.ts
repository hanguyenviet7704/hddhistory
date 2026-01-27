import { IUserFeedback } from "../types/interface/user-feedback.interface";
import axiosClient from "./axiosClient";

export const userFeedbackService = {
  async getByUserId(id: string): Promise<IUserFeedback> {
    const res = await axiosClient.get(`/courses-feedback/${id}`, {});
    return res.data;
  },
};
