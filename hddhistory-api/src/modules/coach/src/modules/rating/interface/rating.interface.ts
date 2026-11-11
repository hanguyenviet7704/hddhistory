import {
  CoachRatingChip,
  CoachSessionKind,
  CoachRatingSource,
  CoachRatingThumb,
} from '../enum/rating.enum';

/**
 * One reader's verdict on one session, asked on the way out.
 *
 * How often it is asked is admin config, not a constant — see
 * `rating-ask-gate.ts`.
 */
export interface ICoachRating {
  userId: string;
  sessionId: string;
  /**
   * Null on everything written since the 👍/👎 toast was removed. The chips
   * carry the sentiment now; this stays readable so old rows still render.
   */
  thumb?: CoachRatingThumb | null;
  chips: CoachRatingChip[];
  /** The reader's own words. Always offered, never required. */
  note?: string | null;
  /** A complaint chip, or any free text at all — see `POSITIVE_RATING_CHIPS`. */
  needsReview: boolean;
  /** The retired rating toast, or the sheet shown on the way out of a session. */
  source: CoachRatingSource;
  /**
   * What the reader was doing when they closed — the chip set they were shown.
   *
   * Null on rows written before 2026-09-14. NOT backfilled: the step those
   * sessions ended on is gone with them, and a guessed kind would make the
   * per-kind numbers read as measured when they were invented.
   */
  sessionKind?: CoachSessionKind | null;
}
