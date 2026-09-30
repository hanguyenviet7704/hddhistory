import { CoachBoostKind } from '../enum/boost.enum';

/**
 * `LichSuBoTro` — when each add-on last appeared for one reader, and whether it
 * is currently muted.
 *
 * `refId` is only used by the course card, whose fatigue rule is per COURSE
 * rather than per feature: "đóng card 3 lần cho cùng một course → không gợi
 * course đó nữa. Course khác vẫn gợi bình thường."
 */
export interface ICoachBoostHistory {
  userId: string;
  kind: CoachBoostKind;
  /** Course id for `card_course`; null for the rest. */
  refId?: string | null;
  lastShownAt?: Date | null;
  /** Consecutive skips. The shared threshold is 3. */
  skipStreak: number;
  /** Muted until this moment. Null while it is free to appear. */
  mutedUntil?: Date | null;
  /** Eligible sessions counted since it last appeared — the rating's 1-in-3. */
  eligibleSince: number;
}
