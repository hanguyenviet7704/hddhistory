import {
  HabitConfigPayload,
  IHabitConfig,
} from "../types/interface/habitConfig.interface";
import axiosClient from "./axiosClient";

// The API wraps every response in { statusCode, message, data } and the axios
// client does NOT unwrap it, so pull the payload out (mirrors warmUpConfigService).
const unwrapData = <T>(payload: any): T => payload?.data ?? payload;

export const habitConfigService = {
  async get(): Promise<IHabitConfig> {
    const res = await axiosClient.get("/habit-config", {});
    return unwrapData<IHabitConfig>(res.data);
  },

  async update(payload: HabitConfigPayload): Promise<IHabitConfig> {
    const res = await axiosClient.put("/habit-config", payload, {});
    return unwrapData<IHabitConfig>(res.data);
  },
};
