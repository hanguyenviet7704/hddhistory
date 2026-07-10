export interface IHabitConfig {
  /** Max simultaneously-active habits for non-premium users (premium is unlimited). */
  freeActiveSlots: number;
}

export interface HabitConfigPayload {
  freeActiveSlots?: number;
}
