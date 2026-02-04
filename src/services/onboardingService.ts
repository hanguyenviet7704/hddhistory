import { OnboardingPayload } from "../types/interface/onboarding.interface";
import { IOnboardingScenarioBranching } from "../types/interface/onboarding-scenario-branching.interface";
import axiosClient from "./axiosClient";
import { axiosClientV2 } from "./axiosClient";

export const onboardingService = {
  async getOne() {
    const res = await axiosClient.get(`/onboardings`, {});
    return res.data;
  },

  async update(id: string, payload: Partial<OnboardingPayload>) {
    return axiosClient.put(`/onboardings/${id}`, payload, {});
  },

  async findScenarioBranching(): Promise<IOnboardingScenarioBranching> {
    const res = await axiosClientV2.get(`/onboardings`, {});
    return res.data;
  },

  async updateScenarioBranching(
    id: string,
    payload: Partial<IOnboardingScenarioBranching>,
  ) {
    return axiosClientV2.put(`/onboardings/${id}`, payload, {});
  },
};
