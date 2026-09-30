import { Injectable, Logger } from '@nestjs/common';
import { InjectConnection, InjectModel } from '@nestjs/mongoose';
import { Connection, Model } from 'mongoose';

import { AbstractRepository } from '@base/database/mongodb/abstract.repository';
import { ITranslation } from '@utils/interface/common.interface';
import { HabitCheckin } from 'src/modules/habit/src/modules/user-habit/schema/habit-checkin.schema';

export interface StudyDayHabit {
  userHabitId: string;
  habitId: string;
  title: ITranslation;
  /** Library artwork for the habit; every habit on dev has one. */
  image?: string;
  method?: string;
  note?: string;
}

/**
 * The "THÓI QUEN ĐƯỢC LUYỆN TẬP" half of a journal day.
 *
 * Separate from [[StudyJournalRepository]] because it reads a different
 * collection with a different day convention: `habit_checkins.date` is stored
 * date-only at UTC midnight (see `normalizeDateOnly`), so a check-in is matched
 * by EQUALITY against that midnight, never by a timezone-shifted window the way
 * keypoint submissions are. Mixing the two rules in one query is how a habit
 * ends up on the wrong day.
 */
@Injectable()
export class StudyJournalHabitRepository extends AbstractRepository<HabitCheckin> {
  protected readonly logger = new Logger(StudyJournalHabitRepository.name);

  constructor(
    @InjectModel(HabitCheckin.name) model: Model<HabitCheckin>,
    @InjectConnection() connection: Connection,
  ) {
    super(model, connection);
  }

  /**
   * Habits this learner ticked on one local day, with their library titles.
   *
   * `done: true` only — an untouched (or explicitly skipped) habit is not a
   * practice, and listing it under "practised" would credit work nobody did.
   * The user filter lives in the `user_habits` lookup because a check-in row
   * knows its habit, not its owner.
   */
  async findDoneOnDate(params: {
    userId: string;
    dateOnlyUtc: Date;
  }): Promise<StudyDayHabit[]> {
    return this.model.aggregate<StudyDayHabit>([
      { $match: { date: params.dateOnlyUtc, done: true } },
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
      // Inner-join semantics: a check-in whose user_habit belongs to someone
      // else (or was deleted) must vanish, not surface with a blank title.
      { $match: { 'userHabit.0': { $exists: true } } },
      {
        $lookup: {
          from: 'habits',
          let: { libraryId: { $first: '$userHabit.habitId' } },
          pipeline: [
            { $match: { $expr: { $eq: ['$_id', '$$libraryId'] } } },
            { $project: { title: 1, image: 1 } },
          ],
          as: 'library',
        },
      },
      { $sort: { createdAt: 1, _id: 1 } },
      {
        $project: {
          _id: 0,
          userHabitId: { $toString: '$userHabitId' },
          habitId: { $toString: { $first: '$userHabit.habitId' } },
          title: { $ifNull: [{ $first: '$library.title' }, {}] },
          image: { $ifNull: [{ $first: '$library.image' }, ''] },
          method: '$method',
          note: '$note',
        },
      },
    ]);
  }
}
