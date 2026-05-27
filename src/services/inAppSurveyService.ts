import {
  InAppSurveyConfigPayload,
  InAppSurveyDateRangeParams,
  InAppSurveyStatisticsOverview,
  InAppSurveyBranchResponsesResult,
  InAppSurveyResponseListParams,
  InAppSurveyResponseListResult,
  InAppSurveyUserResponsesResult,
  IInAppSurveyConfig,
  IInAppSurveyResponse,
} from "../types/interface/in-app-survey.interface";
import axiosClient from "./axiosClient";

const basePath = "/courses-in-app-survey";

const unwrapData = <T>(payload: any): T => payload?.data ?? payload;

export const inAppSurveyService = {
  async getConfig(): Promise<IInAppSurveyConfig> {
    const res = await axiosClient.get(`${basePath}/config`, {});
    return unwrapData<IInAppSurveyConfig>(res.data);
  },

  async saveConfig(payload: InAppSurveyConfigPayload) {
    const res = await axiosClient.put(`${basePath}/config`, payload, {});
    return unwrapData(res.data);
  },

  async getResponsesByUserId(userId: string): Promise<IInAppSurveyResponse[]> {
    const res = await axiosClient.get(
      `${basePath}/responses/users/${userId}`,
      {},
    );
    return unwrapData<IInAppSurveyResponse[]>(res.data);
  },

  async getResponses(
    params: InAppSurveyResponseListParams,
  ): Promise<InAppSurveyResponseListResult> {
    const res = await axiosClient.get(`${basePath}/responses`, { params });
    return unwrapData<InAppSurveyResponseListResult>(res.data);
  },

  async getStatisticsOverview(
    params: InAppSurveyDateRangeParams,
  ): Promise<InAppSurveyStatisticsOverview> {
    const res = await axiosClient.get(`${basePath}/statistics/overview`, {
      params,
    });
    return unwrapData<InAppSurveyStatisticsOverview>(res.data);
  },

  async getBranchResponses(
    branchId: string,
    params: InAppSurveyDateRangeParams & {
      page: number;
      take: number;
      search?: string;
      optionId?: string;
      order?: "asc" | "desc";
    },
  ): Promise<InAppSurveyBranchResponsesResult> {
    const res = await axiosClient.get(
      `${basePath}/statistics/branches/${branchId}/responses`,
      { params },
    );
    return unwrapData<InAppSurveyBranchResponsesResult>(res.data);
  },

  async getUserResponses(
    params: InAppSurveyDateRangeParams & {
      page: number;
      take: number;
      search?: string;
      branchId?: string;
      order?: "asc" | "desc";
    },
  ): Promise<InAppSurveyUserResponsesResult> {
    const res = await axiosClient.get(`${basePath}/statistics/users/responses`, {
      params,
    });
    return unwrapData<InAppSurveyUserResponsesResult>(res.data);
  },

  async exportResponses(
    params: InAppSurveyDateRangeParams & { branchId?: string; lang?: string },
  ): Promise<Blob> {
    const res = await axiosClient.get(`${basePath}/statistics/export`, {
      params,
      responseType: "blob",
    });
    return res.data;
  },
};
