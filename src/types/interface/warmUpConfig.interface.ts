export type WarmUpInactivityUnit = "seconds" | "minutes" | "hours" | "days";

export interface IWarmUpConfig {
  configKey?: string;
  enabled: boolean;
  inactivityValue: number;
  inactivityUnit: WarmUpInactivityUnit;
}

export interface WarmUpConfigPayload {
  enabled?: boolean;
  inactivityValue?: number;
  inactivityUnit?: WarmUpInactivityUnit;
}
