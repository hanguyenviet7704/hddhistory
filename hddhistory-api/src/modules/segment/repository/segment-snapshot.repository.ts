import { Injectable, Logger } from '@nestjs/common';
import { InjectConnection, InjectModel } from '@nestjs/mongoose';
import { Connection, Model } from 'mongoose';

import { AbstractRepository } from '@base/database/mongodb/abstract.repository';

import { SegmentSnapshot } from '../schema/segment-snapshot.schema';

@Injectable()
export class SegmentSnapshotRepository extends AbstractRepository<SegmentSnapshot> {
  protected readonly logger = new Logger(SegmentSnapshotRepository.name);

  constructor(
    @InjectModel(SegmentSnapshot.name) model: Model<SegmentSnapshot>,
    @InjectConnection() connection: Connection,
  ) {
    super(model, connection);
  }

  /**
   * Record today's count — idempotent, so a re-run cron (or a manual refresh
   * that chooses to persist) overwrites rather than duplicates.
   */
  async record(segmentId: string, date: string, count: number): Promise<void> {
    const now = new Date();

    await this.model.updateOne(
      { segmentId, date },
      {
        $set: { count, updatedAt: now },
        $setOnInsert: { createdAt: now },
      },
      { upsert: true },
    );
  }

  /** The last `days` snapshots of one segment, oldest first — chart-ready. */
  async historyFor(segmentId: string, days: number): Promise<SegmentSnapshot[]> {
    return this.model
      .find({ segmentId })
      .sort({ date: -1 })
      .limit(days)
      .lean<SegmentSnapshot[]>()
      .then(rows => rows.reverse());
  }

  /** Drop a deleted segment's history with it. */
  async deleteFor(segmentId: string): Promise<void> {
    await this.model.deleteMany({ segmentId });
  }
}
