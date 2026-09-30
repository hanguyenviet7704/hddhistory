import { Injectable, Logger } from '@nestjs/common';
import { InjectConnection, InjectModel } from '@nestjs/mongoose';
import { Connection, Model } from 'mongoose';

import { AbstractRepository } from '@base/database/mongodb/abstract.repository';

import { CoachProgress } from '../schema/coach-progress.schema';

@Injectable()
export class CoachProgressRepository extends AbstractRepository<CoachProgress> {
  protected readonly logger = new Logger(CoachProgressRepository.name);

  constructor(
    @InjectModel(CoachProgress.name) model: Model<CoachProgress>,
    @InjectConnection() connection: Connection,
  ) {
    super(model, connection);
  }

  /** Newest first, for one reader. */
  async findRecentForUser(userId: string, limit: number) {
    return this.model.find({ userId }).sort({ createdAt: -1 }).limit(limit).lean();
  }
}
