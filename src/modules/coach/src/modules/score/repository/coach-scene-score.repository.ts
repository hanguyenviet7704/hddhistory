import { Injectable, Logger } from '@nestjs/common';
import { InjectConnection, InjectModel } from '@nestjs/mongoose';
import { Connection, Model } from 'mongoose';

import { AbstractRepository } from '@base/database/mongodb/abstract.repository';

import { CoachSceneScore } from '../schema/coach-scene-score.schema';

@Injectable()
export class CoachSceneScoreRepository extends AbstractRepository<CoachSceneScore> {
  protected readonly logger = new Logger(CoachSceneScoreRepository.name);

  constructor(
    @InjectModel(CoachSceneScore.name) model: Model<CoachSceneScore>,
    @InjectConnection() connection: Connection,
  ) {
    super(model, connection);
  }

  /** The reader's recent scores for one skill, newest first. */
  async findRecent(userId: string, habitId: string, take: number) {
    return this.model
      .find({ userId, habitId })
      .sort({ createdAt: -1 })
      .limit(take)
      .lean();
  }

  /** Recent scores across every skill — the profile's "đang tiến bộ ở đâu". */
  async findRecentForUser(userId: string, take: number) {
    return this.model.find({ userId }).sort({ createdAt: -1 }).limit(take).lean();
  }
}
