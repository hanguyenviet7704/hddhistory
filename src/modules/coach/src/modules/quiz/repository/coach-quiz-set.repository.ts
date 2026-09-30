import { Injectable, Logger } from '@nestjs/common';
import { InjectConnection, InjectModel } from '@nestjs/mongoose';
import { Connection, Model } from 'mongoose';

import { AbstractRepository } from '@base/database/mongodb/abstract.repository';

import { CoachQuizSet } from '../schema/coach-quiz-set.schema';

@Injectable()
export class CoachQuizSetRepository extends AbstractRepository<CoachQuizSet> {
  protected readonly logger = new Logger(CoachQuizSetRepository.name);

  constructor(
    @InjectModel(CoachQuizSet.name) model: Model<CoachQuizSet>,
    @InjectConnection() connection: Connection,
  ) {
    super(model, connection);
  }

  /** Every set for these keypoints in this language, newest first. */
  async findForKeypoints(keypointIds: string[], locale: string) {
    if (!keypointIds.length) return [];

    return this.model
      .find({ keypointId: { $in: keypointIds }, locale, 'questions.0': { $exists: true } })
      .sort({ createdAt: -1 })
      .lean();
  }

  async countForKeypoint(keypointId: string, locale: string): Promise<number> {
    return this.model.countDocuments({ keypointId, locale });
  }

  async markServed(id: string): Promise<void> {
    await this.model.updateOne({ _id: id }, { $inc: { servedCount: 1 } });
  }
}
