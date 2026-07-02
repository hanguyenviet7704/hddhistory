import {
  IWarmUpConfig,
  WarmUpConfigPayload,
} from "../types/interface/warmUpConfig.interface";
import axiosClient from "./axiosClient";

// The API wraps every response in { statusCode, message, data } and the axios
// client does NOT unwrap it, so pull the payload out (mirrors inAppSurveyService).
const unwrapData = <T>(payload: any): T => payload?.data ?? payload;

export const warmUpConfigService = {
  async get(): Promise<IWarmUpConfig> {
    const res = await axiosClient.get("/warm-up-config", {});
    return unwrapData<IWarmUpConfig>(res.data);
  },

  async update(payload: WarmUpConfigPayload): Promise<IWarmUpConfig> {
    const res = await axiosClient.put("/warm-up-config", payload, {});
    return unwrapData<IWarmUpConfig>(res.data);
  },
};
