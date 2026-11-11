import {
  IResetOnboardingResult,
  IUser,
  ResetOnboardingPayload,
  UserListQuery,
} from "../types/interface/user.interface";
import axiosClient from "./axiosClient";

export const userService = {
  async getList(params?: Partial<UserListQuery>) {
    const res = await axiosClient.get("/users", { params });
    return res.data;
  },

  async getById(id: string) {
    const res = await axiosClient.get(`/users/${id}`, {});
    return res.data;
  },

  async create(payload: IUser) {
    return axiosClient.post(`/users/register`, payload, {});
  },

  async update(id: string, payload: Partial<IUser>) {
    return axiosClient.put(`/users/${id}`, payload, {});
  },

  async remove(id: string) {
    return axiosClient.delete(`/users/${id}`);
  },

  // The API wraps every response as { statusCode, message, data: <payload> }
  // (see hddhistory-api ResponseInterceptor), so the reset user lives at
  // res.data.data — not res.data. Matches onboardingConfigService /
  // studyThemeService.
  async resetOnboarding(payload: ResetOnboardingPayload) {
    const res = await axiosClient.post<{ data: IResetOnboardingResult }>(
      "/users/reset-onboarding",
      payload
    );
    return res.data.data;
  },
};
