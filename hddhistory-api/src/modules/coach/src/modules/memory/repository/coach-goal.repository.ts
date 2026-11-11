import { Injectable, Logger } from '@nestjs/common';
import { InjectConnection, InjectModel } from '@nestjs/mongoose';
import { Connection, Model } from 'mongoose';

import { AbstractRepository } from '@base/database/mongodb/abstract.repository';

import { CoachGoal } from '../schema/coach-goal.schema';

@Injectable()
export class CoachGoalRepository extends AbstractRepository<CoachGoal> {
  protected readonly logger = new Logger(CoachGoalRepository.name);

  constructor(
    @InjectModel(CoachGoal.name) model: Model<CoachGoal>,
    @InjectConnection() connection: Connection,
  ) {
    super(model, connection);
  }

  async findActiveForUser(userId: string, limit: number) {
    return this.model
      .find({ userId, status: 'active' })
      .sort({ priority: -1, updatedAt: -1 })
      .limit(limit)
      .lean();
  }

  async findByIdsForUser(userId: string, ids: string[]) {
    if (!ids.length) return [];

    return this.model.find({ userId, _id: { $in: ids } }).lean();
  }

  /** Newest first, for one reader. */
  async findRecentForUser(userId: string, limit: number) {
    return this.model.find({ userId }).sort({ createdAt: -1 }).limit(limit).lean();
  }
}
