import { Injectable, Logger } from '@nestjs/common';
import { InjectConnection, InjectModel } from '@nestjs/mongoose';
import { Connection, Model } from 'mongoose';

import { AbstractRepository } from '@base/database/mongodb/abstract.repository';

import { IOnboardingAnswer } from '../interface/onboarding-answer.interface';
import { OnboardingAnswer } from '../schema/onboarding-answer.schema';

@Injectable()
export class OnboardingAnswerRepository extends AbstractRepository<OnboardingAnswer> {
  protected readonly logger = new Logger(OnboardingAnswerRepository.name);
  constructor(
    @InjectModel(OnboardingAnswer.name) model: Model<OnboardingAnswer>,
    @InjectConnection() connection: Connection,
  ) {
    super(model, connection);
  }

  async findByUserId(userId: string): Promise<IOnboardingAnswer | null> {
    return this.model.findOne({ userId }).lean();
  }

  async findByUserIds(userIds: string[]): Promise<IOnboardingAnswer[]> {
    if (!userIds.length) return [];
    return this.model.find({ userId: { $in: userIds } }).lean();
  }

  /** Upsert theo user, chỉ $set các field caller đưa (undefined bị bỏ). */
  async upsertByUserId(
    userId: string,
    patch: Partial<IOnboardingAnswer>,
  ): Promise<IOnboardingAnswer> {
    const $set: Record<string, unknown> = { updatedAt: new Date() };
    for (const [k, v] of Object.entries(patch))
      if (v !== undefined) $set[k] = v;
    return this.model
      .findOneAndUpdate(
        { userId },
        { $set, $setOnInsert: { userId, createdAt: new Date() } },
        { upsert: true, new: true, setDefaultsOnInsert: true },
      )
      .lean() as unknown as Promise<IOnboardingAnswer>;
  }
}
