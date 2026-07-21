import type {
  OnboardingConfig,
  OnboardingConfigPayload,
} from "../types/interface/onboarding-config.interface";
import axiosClient from "./axiosClient";

export const onboardingConfigService = {
  // The API wraps every response as { statusCode, message, data: <payload> }
  // (see meup-api ResponseInterceptor), so the config lives at res.data.data
  // — NOT res.data. Reading res.data here is the exact mistake that caused
  // the study-theme empty-list bug; don't repeat it.
  async getConfig() {
    const res = await axiosClient.get<{ data: OnboardingConfig }>(
      "/onboarding-config"
    );
    return res.data.data;
  },

  // Partial update on the backend, but the admin editor always submits the
  // full content shape since it edits every onboarding screen on one page.
  async updateConfig(payload: OnboardingConfigPayload) {
    const res = await axiosClient.put<{ data: OnboardingConfig }>(
      "/onboarding-config",
      payload
    );
    return res.data.data;
  },
};
