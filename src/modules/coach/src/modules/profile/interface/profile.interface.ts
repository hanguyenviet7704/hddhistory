import { CoachPersona } from '../../../shared/coach.enum';

/**
 * The handful of things about a reader that outlive a session.
 *
 * One document per reader, created on first use. Everything here exists because
 * a rule in the design needs memory across sessions and `coach_sessions` is
 * deliberately short-lived.
 */
export interface ICoachProfile {
  userId: string;
  /** Pre-lit on the persona picker. Never auto-applied — the reader still taps. */
  lastPersona?: CoachPersona | null;
  /**
   * Dead since the 👍/👎 toast was removed (2026-09-14). Kept on the interface
   * because every profile written before that date still carries them, and a
   * reader of the collection should be able to tell what those numbers were.
   */
  ratingSkipCount: number;
  ratingHidden: boolean;
  /** Luồng 6 — when the rating sheet was last ANSWERED. Feeds `ratingAskMinDays`. */
  ratingAskedAt?: Date | null;
  /** Luồng 6 — when it was last closed with ⟨Để sau⟩. Feeds `ratingAskSnoozeDays`. */
  ratingSnoozedAt?: Date | null;
  /** Luồng 6 — asks put in front of this reader ever. Feeds `ratingAskMaxPerUser`. */
  ratingAskCount: number;
  /** Luồng 6 — sessions this reader has closed. Feeds `ratingAskEveryNthExit`. */
  exitCount: number;
  /** Luồng 6 — consecutive sessions closed against the plea; at `EXIT_PLEA_OFF_AFTER` the plea stops. */
  exitDeclinedStreak: number;
  /** Luồng 6 — an answer about leaving is on file, so ⟨Đóng⟩ pleads instead of asking. */
  exitFeedbackGiven: boolean;
  exitFeedbackSkips: number;
  /** Luồng 1 — Onboarding Coach. */
  address?: string | null;
  goalText?: string | null;
  barrierText?: string | null;
  currentPractice?: string | null;
  learningStyle?: string | null;
  occupation?: string | null;
  occupationRaw?: string | null;
  onboardedAt?: Date | null;
  onboardVersion?: number | null;
}
