import { Injectable, Logger } from '@nestjs/common';
import { InjectConnection, InjectModel } from '@nestjs/mongoose';
import { Connection, Model } from 'mongoose';

import { AbstractRepository } from '@base/database/mongodb/abstract.repository';
import { ITranslation } from '@utils/interface/common.interface';
import { HabitCheckin } from 'src/modules/habit/src/modules/user-habit/schema/habit-checkin.schema';

export interface WeekRecapCheckin {
  /** Date-only at UTC midnight, exactly as the row stores it. */
  date: Date;
  done: boolean;
  /** 1..3, or absent when this check-in carried no journal mood. */
  mood?: number;
  habitId: string;
  title: ITranslation;
}

/**
 * Habit check-ins across a whole week, for the poster's mood row and its
 * "THÓI QUEN ĐÃ GIỮ" list.
 *
 * Separate from `StudyJournalHabitRepository` because the question is a
 * different one: that class answers "one day, only what was done", this one
 * answers "seven days, done or not". The `done` filter is deliberately absent —
 * a journal entry carries the day's mood whether or not the habit itself was
 * ticked, and dropping those rows would blank the calendar for a learner who
 * wrote every evening but marked nothing.
 *
 * `date` is matched as a bare UTC midnight, never a shifted window: that is how
 * `normalizeDateOnly` files these rows.
 */
@Injectable()
export class WeekRecapHabitRepository extends AbstractRepository<HabitCheckin> {
  protected readonly logger = new Logger(WeekRecapHabitRepository.name);

  constructor(
    @InjectModel(HabitCheckin.name) model: Model<HabitCheckin>,
    @InjectConnection() connection: Connection,
  ) {
    super(model, connection);
  }

  async findInRange(params: {
    userId: string;
    dateOnlyFrom: Date;
    dateOnlyTo: Date;
  }): Promise<WeekRecapCheckin[]> {
    return this.model.aggregate<WeekRecapCheckin>([
      {
        $match: {
          date: { $gte: params.dateOnlyFrom, $lt: params.dateOnlyTo },
        },
      },
      // The user filter lives in this lookup because a check-in row knows its
      // habit, not its owner.
      {
        $lookup: {
          from: 'user_habits',
          let: { habitRef: '$userHabitId' },
          pipeline: [
            {
              $match: {
                $expr: {
                  $and: [
                    { $eq: ['$_id', '$$habitRef'] },
                    { $eq: ['$userId', params.userId] },
                  ],
                },
              },
            },
            { $project: { habitId: 1 } },
          ],
          as: 'userHabit',
        },
      },
      // Inner-join semantics: a check-in belonging to someone else, or to a
      // habit since deleted, must vanish rather than surface untitled.
      { $match: { 'userHabit.0': { $exists: true } } },
      {
        $lookup: {
          from: 'habits',
          let: { libraryId: { $first: '$userHabit.habitId' } },
          pipeline: [
            { $match: { $expr: { $eq: ['$_id', '$$libraryId'] } } },
            { $project: { title: 1 } },
          ],
          as: 'library',
        },
      },
      { $sort: { date: 1, createdAt: 1, _id: 1 } },
      {
        $project: {
          _id: 0,
          date: '$date',
          done: { $ifNull: ['$done', false] },
          mood: '$mood',
          habitId: { $toString: { $first: '$userHabit.habitId' } },
          title: { $ifNull: [{ $first: '$library.title' }, {}] },
        },
      },
    ]);
  }
}
