import axiosClient from "./axiosClient";

export interface StreakConfig {
  popupEnabled: boolean;
  /** Cumulative foreground seconds in a day before the popup shows. */
  triggerAfterSeconds: number;
  /** 0 = the toast stays until tapped. */
  autoHideSeconds: number;
}

export const streakConfigService = {
  async get() {
    const res = await axiosClient.get("/streak-config");
    return res.data;
  },

  async update(payload: Partial<StreakConfig>) {
    const res = await axiosClient.put("/streak-config", payload);
    return res.data;
  },
};
