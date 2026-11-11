import {
  BehaviorEventsQuery,
  BehaviorRangeQuery,
  IUserBehaviorEventList,
  IUserBehaviorSessionList,
  IUserBehaviorSummary,
} from "../types/interface/analytics.interface";
import axiosClient from "./axiosClient";

// The API wraps every payload as { statusCode, message, data }.
const unwrap = (payload: any) => payload?.data?.data ?? payload?.data ?? payload;

export const analyticsService = {
  async getUserSummary(
    userId: string,
    params?: BehaviorRangeQuery & { funnelPrefix?: string },
  ): Promise<IUserBehaviorSummary> {
    const res = await axiosClient.get(`/analytics/users/${userId}/summary`, {
      params,
    });
    return unwrap(res);
  },

  async getUserSessions(
    userId: string,
    params?: BehaviorRangeQuery & { limit?: number },
  ): Promise<IUserBehaviorSessionList> {
    const res = await axiosClient.get(`/analytics/users/${userId}/sessions`, {
      params,
    });
    return unwrap(res);
  },

  async getSessionEvents(
    userId: string,
    params: BehaviorEventsQuery,
  ): Promise<IUserBehaviorEventList> {
    const res = await axiosClient.get(`/analytics/users/${userId}/events`, {
      params,
    });
    return unwrap(res);
  },
};
