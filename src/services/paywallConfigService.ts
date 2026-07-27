import { PaywallEnvironment } from "../types/enum/paywall-config.enum";
import { PaywallConfig } from "../types/interface/paywall-config.interface";
import axiosClient from "./axiosClient";

export const paywallConfigService = {
  async getConfig(environment: PaywallEnvironment) {
    const res = await axiosClient.get("/paywall-config", {
      params: { environment },
    });
    return res.data;
  },

  async updateConfig(environment: PaywallEnvironment, payload: PaywallConfig) {
    const res = await axiosClient.put("/paywall-config", payload, {
      params: { environment },
    });
    return res.data;
  },
};
