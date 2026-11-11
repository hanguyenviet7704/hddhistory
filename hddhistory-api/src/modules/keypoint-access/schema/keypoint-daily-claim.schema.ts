import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose';

import { AbstractDocument } from '@base/database/mongodb/abstract.schema';

/**
 * The keypoints a reader FINISHED today — the daily free-keypoint ledger.
 *
 * One row per (user, day), enforced by the unique index below rather than by
 * application code, holding one entry per keypoint completed in [keypointIds]. A
 * row per completion would have been the obvious shape; the day row is what lets
 * the whole gate be answered by a single indexed read on keypoint entry, which is
 * a hot path.
 *
 * Since 2026-08-21 the entries are COMPLETIONS, not passages: finishing a keypoint
 * is what spends the day (`UserProgressService` writes it), and reading part of one
 * and leaving writes nothing. How many entries make a full day is the config's
 * business (`freeKeypointsPerDay`), applied when the row is read.
 *
 * It also needs no index migration. The original (userId, dayKey) unique index was
 * written when the quota was fixed at one per day; it is already deployed, and
 * making it (userId, dayKey, keypointId) would have left the old unique index in
 * place on every existing database — silently still capping the day at one, which
 * is the very bug this shape fixes (admin set 3/day, readers still got 1,
 * 2026-08-12).
 */
@Schema({ collection: 'keypoint_daily_claims' })
export class KeypointDailyClaim extends AbstractDocument {
  @Prop({ type: String, required: true, index: true })
  userId: string;

  /**
   * The READER's calendar day as `YYYY-MM-DD` (see `dayKeyFor`), not the server's.
   *
   * Stored as the string it was decided as: recomputing a day from a timestamp at
   * read time would need the offset again, and a reader who travels would then find
   * yesterday's claim moved.
   */
  @Prop({ type: String, required: true })
  dayKey: string;

  /**
   * The FIRST keypoint of the day, kept for rows written before the quota could
   * exceed one per day. Read through `claimedKeypointIds`, never on its own.
   * Rows from before 2026-08-21 hold the keypoint the reader walked PAST the lock
   * on rather than one they finished; a stale row costs at most that reader's
   * current day, so there is nothing to migrate.
   */
  @Prop({ type: String, required: false })
  keypointId?: string;

  /**
   * Every keypoint the reader finished today. Returning to any of them the same day
   * stays free, as does re-reading them on any later day.
   */
  @Prop({ type: [String], default: [] })
  keypointIds: string[];

  @Prop({ type: Date, default: Date.now })
  claimedAt: Date;
}

export const KeypointDailyClaimSchema =
  SchemaFactory.createForClass(KeypointDailyClaim);

// One ledger ROW per reader per day. How many keypoints that row may hold is the
// config's business (`freeKeypointsPerDay`), not the index's.
KeypointDailyClaimSchema.index({ userId: 1, dayKey: 1 }, { unique: true });
