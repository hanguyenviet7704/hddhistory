import { OnboardingPayload } from "../types/interface/onboarding.interface";
import axiosClient from "./axiosClient";

export const onboardingService = {
  async getOne() {
    const res = await axiosClient.get(`/onboardings`, {});
    return res.data;
  },

  async update(id: string, payload: Partial<OnboardingPayload>) {
    return axiosClient.put(`/onboardings/${id}`, payload, {});
  },
};
