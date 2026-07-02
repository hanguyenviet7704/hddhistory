export interface IWarmUpConfig {
  configKey?: string;
  enabled: boolean;
  inactivityDays: number;
}

export interface WarmUpConfigPayload {
  enabled?: boolean;
  inactivityDays?: number;
}
