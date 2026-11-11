import { WarmUpInactivityUnit } from '../enum/warm-up-inactivity-unit.enum';

export interface IWarmUpConfig {
  configKey: string;
  enabled: boolean;
  inactivityValue: number;
  inactivityUnit: WarmUpInactivityUnit;
  /**
   * @deprecated Superseded by {@link inactivityValue} + {@link inactivityUnit}.
   * Kept optional so pre-existing documents still round-trip on read.
   */
  inactivityDays?: number;
}
