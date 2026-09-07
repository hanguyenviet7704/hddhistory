import {
  ICoachMetricsWeek,
  ICoachStatsPage,
} from "../types/interface/coachStats.interface";
import {
  IDashboardQuery,
  ILearningPage,
  IOnboardingPage,
  IOverviewPage,
  ISessionsPage,
  IUsersPage,
} from "../types/interface/dashboard.interface";
import axiosClient from "./axiosClient";

// The API wraps every payload as { statusCode, message, data } — same unwrap
// the behaviour tab's analyticsService uses.
const unwrap = (payload: any) => payload?.data?.data ?? payload?.data ?? payload;

const basePath = "/analytics/dashboard";

export const dashboardService = {
  async getOverview(params: IDashboardQuery): Promise<IOverviewPage> {
    const res = await axiosClient.get(`${basePath}/overview`, { params });
    return unwrap(res);
  },

  async getUsers(params: IDashboardQuery): Promise<IUsersPage> {
    const res = await axiosClient.get(`${basePath}/users`, { params });
    return unwrap(res);
  },

  async getSessions(params: IDashboardQuery): Promise<ISessionsPage> {
    const res = await axiosClient.get(`${basePath}/sessions`, { params });
    return unwrap(res);
  },

  async getOnboarding(params: IDashboardQuery): Promise<IOnboardingPage> {
    const res = await axiosClient.get(`${basePath}/onboarding`, { params });
    return unwrap(res);
  },

  async getLearning(params: IDashboardQuery): Promise<ILearningPage> {
    const res = await axiosClient.get(`${basePath}/learning`, { params });
    return unwrap(res);
  },

  async getCoach(params: IDashboardQuery): Promise<ICoachStatsPage> {
    const res = await axiosClient.get(`${basePath}/coach`, { params });
    return unwrap(res);
  },

  /**
   * The Coach's own weekly counters — a different endpoint and a different
   * grain from everything above, so it takes an ISO week rather than a range.
   * Omitting the week asks for the most recent one that has data.
   */
  async getCoachMetrics(isoWeek?: string): Promise<ICoachMetricsWeek> {
    const res = await axiosClient.get("/coach-metrics", {
      params: isoWeek ? { isoWeek } : undefined,
    });
    return unwrap(res);
  },
};
