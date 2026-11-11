import { Injectable, Logger } from '@nestjs/common';
import { InjectConnection, InjectModel } from '@nestjs/mongoose';
import { Connection, Model } from 'mongoose';

import { AbstractRepository } from '@base/database/mongodb/abstract.repository';

import { HabitPracticeAttempt } from '../schema/habit-practice-attempt.schema';

@Injectable()
export class HabitPracticeAttemptRepository extends AbstractRepository<HabitPracticeAttempt> {
  protected readonly logger = new Logger(
    HabitPracticeAttemptRepository.name,
  );

  constructor(
    @InjectModel(HabitPracticeAttempt.name)
    model: Model<HabitPracticeAttempt>,
    @InjectConnection() connection: Connection,
  ) {
    super(model, connection);
  }

  // Newest-first log for one adopted habit. Unlike habit_checkins there can be
  // several rows per day, so `completedAt` breaks the tie within a date.
  async findForUserHabit(userHabitId: string, from?: Date, to?: Date) {
    const dateFilter: Record<string, Date> = {};
    if (from) dateFilter.$gte = from;
    if (to) dateFilter.$lte = to;

    return this.model
      .find({
        userHabitId,
        ...(Object.keys(dateFilter).length ? { date: dateFilter } : {}),
      })
      .sort({ date: -1, completedAt: -1 })
      .lean();
  }

  async findForUserHabits(userHabitIds: string[], from?: Date, to?: Date) {
    if (!userHabitIds.length) return [];

    const dateFilter: Record<string, Date> = {};
    if (from) dateFilter.$gte = from;
    if (to) dateFilter.$lte = to;

    return this.model
      .find({
        userHabitId: { $in: userHabitIds },
        ...(Object.keys(dateFilter).length ? { date: dateFilter } : {}),
      })
      .sort({ date: -1, completedAt: -1 })
      .lean();
  }
}
