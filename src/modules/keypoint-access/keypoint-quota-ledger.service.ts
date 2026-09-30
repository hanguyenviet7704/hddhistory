import { Injectable } from '@nestjs/common';

import { dayKeyFor, isUserLessonKeypointId } from './keypoint-access.util';
import {
  claimedKeypointIds,
  KeypointDailyClaimRepository,
} from './repository/keypoint-daily-claim.repository';

/**
 * How many keypoints one day's row may hold.
 *
 * A growth backstop, NOT the quota: the quota's own limit is applied when the row
 * is read (see `KeypointAccessService`), because by the time a completion is
 * written the reader has already done the work and the row is simply recording
 * what happened. Nobody finishes two hundred keypoints in a day; a client looping
 * the progress endpoint could still try, and an unbounded array is how that turns
 * into a document-size failure on a real reader's row.
 */
const MAX_LEDGER_ENTRIES = 200;

/**
 * The daily free-keypoint ledger: which keypoints this reader FINISHED today.
 *
 * A leaf on purpose — it depends on nothing but its own collection. The write side
 * belongs to `UserProgressService` (finishing a keypoint is what spends the day's
 * ticket, product call 2026-08-21) and the read side to `KeypointAccessService`,
 * and those two live on opposite sides of the module graph: putting the config and
 * subscription lookups in here as well would drag `PaywallConfigModule` — and
 * through it `AuthModule` — into the courses tree, closing an import cycle that
 * only shows up as a crash on boot.
 */
@Injectable()
export class KeypointQuotaLedgerService {
  constructor(private readonly claimRepository: KeypointDailyClaimRepository) {}

  /**
   * The keypoints this reader finished today, oldest first.
   *
   * The day is the READER's (see `dayKeyFor`), so someone studying at 00:30 in
   * Hanoi is not filed under yesterday.
   */
  async completedToday(userId: string, offsetMinutes: number): Promise<string[]> {
    if (!userId) return [];

    const claim = await this.claimRepository.findClaim(
      userId,
      dayKeyFor(new Date(), offsetMinutes),
    );

    return claimedKeypointIds(claim);
  }

  /**
   * Record one finished keypoint — the single place the daily ticket is spent.
   *
   * Called after the keypoint has actually been marked passed, and ONLY for one
   * the reader had not passed before: re-finishing an old keypoint is revision,
   * and revision is free.
   *
   * Never throws. The reader's progress is what matters on that request; a ledger
   * row that failed to write costs at most one free keypoint, while an exception
   * here would fail the call that saved the work they just did.
   *
   * Premium readers are recorded too. The ledger is only ever READ for someone the
   * quota applies to (every path in `KeypointAccessService` short-circuits premium
   * first), so the row changes nothing for them — and leaving the subscription
   * lookup out keeps it off the completion path entirely.
   */
  async recordCompletion(params: {
    userId: string;
    keypointId: string;
    offsetMinutes: number;
  }): Promise<void> {
    const { userId, keypointId, offsetMinutes } = params;
    // Content the reader generated is outside the quota entirely, and its ids name
    // nothing in the catalogue.
    if (!userId || !keypointId || isUserLessonKeypointId(keypointId)) return;

    try {
      await this.claimRepository.claim(
        userId,
        dayKeyFor(new Date(), offsetMinutes),
        keypointId,
        MAX_LEDGER_ENTRIES,
      );
    } catch (error) {
      // Deliberately swallowed: see the doc above.
      // eslint-disable-next-line no-console
      console.warn('[keypoint-access] ledger write failed, day not charged', error);
    }
  }
}
