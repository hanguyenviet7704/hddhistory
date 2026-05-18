import {
  InAppSurveyConfigPayload,
  InAppSurveyResponseListParams,
  InAppSurveyResponseListResult,
  IInAppSurveyConfig,
  IInAppSurveyResponse,
} from "../types/interface/in-app-survey.interface";
import axiosClient from "./axiosClient";

const basePath = "/courses-in-app-survey";

export const inAppSurveyService = {
  async getConfig(): Promise<IInAppSurveyConfig> {
    const res = await axiosClient.get(`${basePath}/config`, {});
    return res.data;
  },

  async saveConfig(payload: InAppSurveyConfigPayload) {
    const res = await axiosClient.put(`${basePath}/config`, payload, {});
    return res.data;
  },

  async getResponsesByUserId(userId: string): Promise<IInAppSurveyResponse[]> {
    const res = await axiosClient.get(
      `${basePath}/responses/users/${userId}`,
      {},
    );
    return res.data;
  },

  async getResponses(
    params: InAppSurveyResponseListParams,
  ): Promise<InAppSurveyResponseListResult> {
    const res = await axiosClient.get(`${basePath}/responses`, { params });
    return res.data;
  },
};
