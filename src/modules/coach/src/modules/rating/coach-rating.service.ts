import { Injectable } from '@nestjs/common';

import {
  CoachRatingChip,
  CoachSessionKind,
  CoachRatingSource,
  POSITIVE_RATING_CHIPS,
} from './enum/rating.enum';
import { CoachRatingRepository } from './repository/coach-rating.repository';

@Injectable()
export class CoachRatingService {
  constructor(private readonly repository: CoachRatingRepository) {}

  /**
   * Whether this answer has to be read by a person.
   *
   * Any complaint chip, or any free text at all — somebody who took the trouble
   * to type has said something a closed list could not hold, and that is true
   * even when every chip they ticked was praise. Pure praise with no words is
   * the one shape that needs nobody.
   */
  private static needsReview(chips: CoachRatingChip[], note?: string | null): boolean {
    if (note?.trim()) return true;

    return chips.some((chip) => !POSITIVE_RATING_CHIPS.has(chip));
  }

  /**
   * One answer from the sheet shown after ⟨Vẫn đóng⟩.
   *
   * Every row is kept, unsampled — praise included. The queue a person works
   * through is `needsReview`; the rest is what tells you whether the complaints
   * are the whole story or the loud end of it.
   */
  async record(params: {
    userId: string;
    sessionId: string;
    chips?: CoachRatingChip[];
    /** The reader's own words. */
    note?: string | null;
    source?: CoachRatingSource;
    /** What they were doing when they closed — which chip set they answered. */
    sessionKind?: CoachSessionKind | null;
  }) {
    const { userId, sessionId, chips, note, source, sessionKind } = params;
    const picked = chips ?? [];

    return this.repository.create({
      userId,
      sessionId,
      thumb: null,
      chips: picked,
      note: note?.trim() || null,
      needsReview: CoachRatingService.needsReview(picked, note),
      source: source ?? CoachRatingSource.EXIT,
      sessionKind: sessionKind ?? null,
    });
  }

  /**
   * Passed through as asked, including an absent `needsReview`.
   *
   * It used to default to the open queue. Since praise never enters that queue,
   * defaulting to it would make a screen whose whole job is showing what people
   * think permanently blind to half the answers — the caller says which view it
   * wants, and "everything" is a view.
   */
  async findForAdmin(filter: {
    needsReview?: boolean;
    source?: CoachRatingSource;
    sessionKind?: CoachSessionKind;
    from?: string;
    to?: string;
  }) {
    return this.repository.findForAdmin(filter);
  }

  async markReviewed(id: string) {
    return this.repository.markReviewed(id);
  }
}
