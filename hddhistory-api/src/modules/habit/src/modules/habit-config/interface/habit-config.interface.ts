export interface IHabitConfig {
  configKey: string;
  /** Max simultaneously-active habits for users WITHOUT a premium subscription. */
  freeActiveSlots: number;
}
