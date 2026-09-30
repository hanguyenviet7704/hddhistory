import { Injectable, Logger } from '@nestjs/common';
import { InjectConnection, InjectModel } from '@nestjs/mongoose';
import { Connection, Model } from 'mongoose';

import { AbstractRepository } from '@base/database/mongodb/abstract.repository';

import { KeypointDailyClaim } from '../schema/keypoint-daily-claim.schema';

@Injectable()
export class KeypointDailyClaimRepository extends AbstractRepository<KeypointDailyClaim> {
  protected readonly logger = new Logger(KeypointDailyClaimRepository.name);

  constructor(
    @InjectModel(KeypointDailyClaim.name) model: Model<KeypointDailyClaim>,
    @InjectConnection() connection: Connection,
  ) {
    super(model, connection);
  }

  /** Today's ledger row for this reader, or null when they have finished nothing yet. */
  async findClaim(
    userId: string,
    dayKey: string,
  ): Promise<KeypointDailyClaim | null> {
    return this.model.findOne({ userId, dayKey }).lean();
  }

  /**
   * Records [keypointId] in today's row and reports the row as it stands
   * afterwards — which is all the caller needs: whether the keypoint is in
   * `keypointIds` IS whether it is on record.
   *
   * Two atomic steps, no read-then-write anywhere:
   *
   * 1. Upsert the day's row with this keypoint already in it. The unique
   *    (userId, dayKey) index makes exactly one concurrent caller the inserter.
   * 2. If the row already existed, `$addToSet` under a SIZE GUARD in the filter.
   *    Mongo evaluates filter and update as one operation, so concurrent writers
   *    cannot push the row past [limit] between a read and a write.
   *
   * [limit] is a GROWTH BACKSTOP, not the quota. Since 2026-08-21 a row records
   * what the reader FINISHED today, and the quota's own limit is applied when
   * `KeypointAccessService` reads it: a completion that already happened is a fact,
   * and refusing to write it would only make the ledger disagree with the reader's
   * own progress. The guard refusing (null result) is not an error.
   *
   * `upsert` can still race two inserts into a duplicate-key error; Mongo raises it
   * on exactly one of them, and re-reading is then guaranteed to find the winner.
   */
  async claim(
    userId: string,
    dayKey: string,
    keypointId: string,
    limit: number,
  ): Promise<KeypointDailyClaim> {
    const existing = await this.upsertDay(userId, dayKey, keypointId);
    const held = claimedKeypointIds(existing);
    if (held.includes(keypointId)) return existing;
    if (held.length >= limit) return existing;

    const grown = await this.model
      .findOneAndUpdate(
        {
          userId,
          dayKey,
          // The count as MONGO sees it at write time, not as we read it. `$ifNull`
          // covers rows written before `keypointIds` existed.
          $expr: {
            $lt: [{ $size: { $ifNull: ['$keypointIds', []] } }, limit],
          },
        },
        { $addToSet: { keypointIds: keypointId }, $set: { updatedAt: new Date() } },
        { new: true },
      )
      .lean();

    // Guard refused (the row hit its backstop between the two operations): report
    // it as it really is rather than assuming the write landed.
    return grown ?? existing;
  }

  /**
   * The day's row, creating it with [keypointId] already claimed when this is the
   * first ticket of the day.
   */
  private async upsertDay(
    userId: string,
    dayKey: string,
    keypointId: string,
  ): Promise<KeypointDailyClaim> {
    try {
      return await this.model
        .findOneAndUpdate(
          { userId, dayKey },
          {
            $setOnInsert: {
              userId,
              dayKey,
              keypointId,
              keypointIds: [keypointId],
              claimedAt: new Date(),
              createdAt: new Date(),
              updatedAt: new Date(),
            },
          },
          { upsert: true, new: true, setDefaultsOnInsert: true },
        )
        .lean();
    } catch (error: any) {
      // 11000 = duplicate key: another request inserted between our read and our
      // write. Not an error condition — it means someone won, and the re-read below
      // says who.
      if (error?.code !== 11000) throw error;

      const existing = await this.findClaim(userId, dayKey);
      if (existing) return existing;
      throw error;
    }
  }
}

/**
 * The keypoints a day row holds.
 *
 * Rows written before the quota could exceed one per day carry a single
 * `keypointId` and no array — reading only `keypointIds` would hand those readers a
 * fresh day for a keypoint already on record.
 */
export function claimedKeypointIds(
  claim: Pick<KeypointDailyClaim, 'keypointId' | 'keypointIds'> | null,
): string[] {
  if (!claim) return [];
  if (claim.keypointIds?.length) return claim.keypointIds;

  return claim.keypointId ? [claim.keypointId] : [];
}
