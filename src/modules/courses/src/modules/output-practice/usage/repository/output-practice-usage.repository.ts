import { Injectable, Logger } from '@nestjs/common';
import { InjectConnection, InjectModel } from '@nestjs/mongoose';
import { Connection, Model } from 'mongoose';

import { IUserMeta } from '@base/database/mongodb/abstract.interface';
import { AbstractRepository } from '@base/database/mongodb/abstract.repository';

import { OutputPracticeUsage } from '../schema/output-practice-usage.schema';

@Injectable()
export class OutputPracticeUsageRepository extends AbstractRepository<OutputPracticeUsage> {
  protected readonly logger = new Logger(OutputPracticeUsageRepository.name);

  constructor(
    @InjectModel(OutputPracticeUsage.name)
    model: Model<OutputPracticeUsage>,
    @InjectConnection() connection: Connection,
  ) {
    super(model, connection);
  }

  async getUsedCount(userId: string, sectionId: string, monthKey: string) {
    const usage = await this.model
      .findOne(
        { userId, sectionId, monthKey },
        { usedCount: 1 },
        { lean: true },
      )
      .exec();

    return usage?.usedCount || 0;
  }

  async consumeMonthlyAttempt(
    userId: string,
    sectionId: string,
    monthKey: string,
    limit: number,
    user?: IUserMeta,
  ) {
    const filter = {
      userId,
      sectionId,
      monthKey,
      usedCount: { $lt: limit },
    };

    // Step 1: try to consume a remaining slot from the current month record.
    const updated = await this.model
      .findOneAndUpdate(
        filter,
        { $inc: { usedCount: 1 } },
        { new: true, lean: true },
      )
      .exec();

    if (updated) {
      return updated as OutputPracticeUsage;
    }

    try {
      // Step 2: first successful create in a month starts the counter at 1.
      return await this.create(
        {
          userId,
          sectionId,
          monthKey,
          usedCount: 1,
        },
        user,
      );
    } catch (error: any) {
      if (error?.code !== 11000) {
        throw error;
      }
    }

    // Step 3: concurrent create requests may race on the first insert.
    // Retrying the increment once keeps the logic deterministic.
    return this.model
      .findOneAndUpdate(
        filter,
        { $inc: { usedCount: 1 } },
        { new: true, lean: true },
      )
      .exec();
  }
}
