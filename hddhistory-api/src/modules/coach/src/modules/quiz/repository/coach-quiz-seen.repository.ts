import { Injectable, Logger } from '@nestjs/common';
import { InjectConnection, InjectModel } from '@nestjs/mongoose';
import { Connection, Model } from 'mongoose';

import { AbstractRepository } from '@base/database/mongodb/abstract.repository';

import { CoachQuizSeen } from '../schema/coach-quiz-seen.schema';

@Injectable()
export class CoachQuizSeenRepository extends AbstractRepository<CoachQuizSeen> {
  protected readonly logger = new Logger(CoachQuizSeenRepository.name);

  constructor(
    @InjectModel(CoachQuizSeen.name) model: Model<CoachQuizSeen>,
    @InjectConnection() connection: Connection,
  ) {
    super(model, connection);
  }

  /** Of these sets, the ones this reader has already been asked. */
  async seenSetIds(userId: string, setIds: string[]): Promise<Set<string>> {
    if (!setIds.length) return new Set();
    const rows = (await this.model
      .find({ userId, setId: { $in: setIds } })
      .select('setId')
      .lean()) as Array<{ setId?: string }>;

    return new Set(rows.map((row) => String(row.setId)));
  }

  /** Idempotent: the same reader marking the same set twice is not an error. */
  async markSeen(userId: string, setId: string, keypointId: string): Promise<void> {
    await this.model.updateOne(
      { userId, setId },
      { $setOnInsert: { userId, setId, keypointId } },
      { upsert: true },
    );
  }
}
