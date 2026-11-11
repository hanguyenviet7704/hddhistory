import { Injectable, Logger } from '@nestjs/common';
import { InjectConnection, InjectModel } from '@nestjs/mongoose';
import { Connection, Model } from 'mongoose';

import { AbstractRepository } from '@base/database/mongodb/abstract.repository';

import { CoachMemoryCard } from '../schema/coach-memory-card.schema';

@Injectable()
export class CoachMemoryCardRepository extends AbstractRepository<CoachMemoryCard> {
  protected readonly logger = new Logger(CoachMemoryCardRepository.name);

  constructor(
    @InjectModel(CoachMemoryCard.name) model: Model<CoachMemoryCard>,
    @InjectConnection() connection: Connection,
  ) {
    super(model, connection);
  }

  async findForUser(userId: string) {
    return this.model.findOne({ userId }).lean();
  }

  /** Một doc mỗi user, ghi đè tại chỗ — thẻ là thứ dựng lại được, không phải lịch sử. */
  async save(userId: string, patch: Partial<CoachMemoryCard>) {
    await this.model.updateOne(
      { userId },
      { $set: { ...patch, userId } },
      { upsert: true },
    );
  }

  async markGreetingUsed(userId: string, at: Date) {
    await this.model.updateOne({ userId }, { $set: { greetingUsedAt: at } });
  }
}
