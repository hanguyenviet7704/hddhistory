import { Injectable, Logger } from '@nestjs/common';
import { InjectConnection, InjectModel } from '@nestjs/mongoose';
import { Connection, Model } from 'mongoose';

import { AbstractRepository } from '@base/database/mongodb/abstract.repository';

import { CoachBoostKind } from '../enum/boost.enum';
import { CoachBoostHistory } from '../schema/coach-boost-history.schema';

@Injectable()
export class CoachBoostHistoryRepository extends AbstractRepository<CoachBoostHistory> {
  protected readonly logger = new Logger(CoachBoostHistoryRepository.name);

  constructor(
    @InjectModel(CoachBoostHistory.name) model: Model<CoachBoostHistory>,
    @InjectConnection() connection: Connection,
  ) {
    super(model, connection);
  }

  /** Every add-on's state for one reader, in one read. */
  async findForUser(userId: string) {
    return this.model.find({ userId }).lean();
  }

  async findOneFor(userId: string, kind: CoachBoostKind, refId: string | null = null) {
    return this.model.findOne({ userId, kind, refId }).lean();
  }

  /**
   * Upsert one add-on's state.
   *
   * `$setOnInsert` on the key so two turns racing to record the same add-on do
   * not fight over who created the row.
   */
  async record(
    userId: string,
    kind: CoachBoostKind,
    refId: string | null,
    patch: Partial<CoachBoostHistory>,
  ) {
    return this.model
      .findOneAndUpdate(
        { userId, kind, refId },
        { $set: patch, $setOnInsert: { userId, kind, refId } },
        { upsert: true, new: true, setDefaultsOnInsert: true },
      )
      .lean();
  }

  /** +1 to the eligible-session counter of one add-on. */
  async bumpEligible(userId: string, kind: CoachBoostKind) {
    return this.model.updateOne(
      { userId, kind, refId: null },
      { $inc: { eligibleSince: 1 }, $setOnInsert: { userId, kind, refId: null } },
      { upsert: true },
    );
  }
}
