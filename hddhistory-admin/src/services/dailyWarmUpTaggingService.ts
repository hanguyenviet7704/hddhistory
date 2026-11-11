import { DailyWarmUpTaggingResult } from "../types/interface/learning-item/daily-warm-up-tagging.interface";
import axiosClient from "./axiosClient";

// The API wraps every response in { statusCode, message, data } and the axios
// client does NOT unwrap it, so pull the payload out (mirrors warmUpConfigService).
const unwrapData = <T>(payload: any): T => payload?.data ?? payload;

const BASE = "/courses-learning-items/daily-warm-up-tagging";

export const dailyWarmUpTaggingService = {
  // Dry run: compute the rule across the whole catalog without writing.
  async preview(): Promise<DailyWarmUpTaggingResult> {
    const res = await axiosClient.get(`${BASE}/preview`, {});
    return unwrapData<DailyWarmUpTaggingResult>(res.data);
  },

  // Full sync: compute the rule then persist. Idempotent.
  async apply(): Promise<DailyWarmUpTaggingResult> {
    const res = await axiosClient.post(`${BASE}/apply`, {}, {});
    return unwrapData<DailyWarmUpTaggingResult>(res.data);
  },
};
