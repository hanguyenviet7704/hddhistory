import { Injectable, Logger } from '@nestjs/common';
import { InjectConnection, InjectModel } from '@nestjs/mongoose';
import { Connection, Model } from 'mongoose';

import { AbstractRepository } from '@base/database/mongodb/abstract.repository';

import { HabitCheckinMethod } from '../enum/user-habit.enum';
import { HabitCheckin } from '../schema/habit-checkin.schema';

/**
 * One check-in as the admin export needs it — flat, already joined to the user
 * and the library habit.
 *
 * Declared rather than inferred because `tsconfig.build.json` compiles with
 * `strict: true` while `tsconfig.json` does not: an untyped `aggregate()` result
 * passes `npx tsc --noEmit` locally and fails the Jenkins build on implicit any.
 */
export interface IHabitCheckinExportRow {
  date: Date;
  done: boolean;
  method?: HabitCheckinMethod;
  mood?: number;
  score?: number;
  note?: string;
  userId?: unknown;
  habitId?: unknown;
  habitTitle?: Record<string, string>;
  createdAt?: Date;
}

@Injectable()
export class HabitCheckinRepository extends AbstractRepository<HabitCheckin> {
  protected readonly logger = new Logger(HabitCheckinRepository.name);

  constructor(
    @InjectModel(HabitCheckin.name) model: Model<HabitCheckin>,
    @InjectConnection() connection: Connection,
  ) {
    super(model, connection);
  }

  async upsertDay(
    userHabitId: string,
    date: Date,
    done: boolean,
    extras?: {
      note?: string;
      method?: HabitCheckinMethod;
      mood?: number;
      score?: number;
    },
  ) {
    const $set: Record<string, unknown> = { userHabitId, date, done };
    // Only touch the optional fields the caller actually passed. Re-checking a
    // day must not wipe a previously saved diary entry, mood or quiz score —
    // the quick 7-day-strip toggle sends only `done`.
    for (const key of ['note', 'method', 'mood', 'score'] as const) {
      const value = extras?.[key];
      if (value !== undefined) $set[key] = value;
    }
    return this.model.findOneAndUpdate(
      { userHabitId, date },
      { $set },
      { upsert: true, new: true, setDefaultsOnInsert: true },
    );
  }

  /**
   * Everything the admin statistics tab draws, in one round trip.
   *
   * A check-in row only knows its `userHabitId`, so the pipeline joins up to
   * `user_habits` (for the user and which library habit it is) and then to
   * `habits` (for the title). That join is what makes "top habit" and "số người
   * check-in" possible at all — the rows themselves carry neither.
   *
   * Unlike the lesson-feedback aggregation, nothing here is a per-user latest
   * snapshot: the unique index is (userHabitId, date), so every row is one real
   * day of one habit and the counts are counts of events.
   */
  async aggregateStatistics(from?: Date, to?: Date) {
    const dateMatch: Record<string, Date> = {};
    if (from) dateMatch.$gte = from;
    if (to) dateMatch.$lte = to;

    const [result] = await this.model
      .aggregate([
        ...(Object.keys(dateMatch).length ? [{ $match: { date: dateMatch } }] : []),
        {
          $lookup: {
            from: 'user_habits',
            localField: 'userHabitId',
            foreignField: '_id',
            as: 'userHabit',
          },
        },
        // An orphaned check-in (its user_habit was hard-deleted) would otherwise
        // count toward totals with no user and no habit to attribute it to.
        { $unwind: '$userHabit' },
        {
          $project: {
            date: 1,
            done: 1,
            note: 1,
            method: { $ifNull: ['$method', 'tap'] },
            mood: 1,
            score: 1,
            userId: '$userHabit.userId',
            habitId: '$userHabit.habitId',
          },
        },
        {
          $facet: {
            totals: [
              {
                $group: {
                  _id: null,
                  checkins: { $sum: 1 },
                  done: { $sum: { $cond: ['$done', 1, 0] } },
                  users: { $addToSet: '$userId' },
                  habits: { $addToSet: '$habitId' },
                  withNote: {
                    $sum: {
                      $cond: [
                        {
                          $gt: [
                            {
                              $strLenCP: {
                                $trim: { input: { $ifNull: ['$note', ''] } },
                              },
                            },
                            0,
                          ],
                        },
                        1,
                        0,
                      ],
                    },
                  },
                  moodSum: { $sum: { $ifNull: ['$mood', 0] } },
                  moodCount: {
                    $sum: { $cond: [{ $gte: ['$mood', 1] }, 1, 0] },
                  },
                  quizCount: {
                    $sum: { $cond: [{ $gte: ['$score', 0] }, 1, 0] },
                  },
                  quizScoreSum: { $sum: { $ifNull: ['$score', 0] } },
                },
              },
              {
                $project: {
                  _id: 0,
                  checkins: 1,
                  done: 1,
                  withNote: 1,
                  users: { $size: '$users' },
                  habits: { $size: '$habits' },
                  moodSum: 1,
                  moodCount: 1,
                  quizCount: 1,
                  quizScoreSum: 1,
                },
              },
            ],
            daily: [
              {
                $group: {
                  _id: '$date',
                  checkins: { $sum: 1 },
                  done: { $sum: { $cond: ['$done', 1, 0] } },
                  users: { $addToSet: '$userId' },
                },
              },
              {
                $project: {
                  _id: 0,
                  date: '$_id',
                  checkins: 1,
                  done: 1,
                  users: { $size: '$users' },
                },
              },
              { $sort: { date: 1 } },
            ],
            methods: [
              { $group: { _id: '$method', count: { $sum: 1 } } },
              { $project: { _id: 0, method: '$_id', count: 1 } },
              { $sort: { count: -1 } },
            ],
            moods: [
              { $match: { mood: { $gte: 1 } } },
              { $group: { _id: '$mood', count: { $sum: 1 } } },
              { $project: { _id: 0, mood: '$_id', count: 1 } },
              { $sort: { mood: 1 } },
            ],
            topHabits: [
              {
                $group: {
                  _id: '$habitId',
                  checkins: { $sum: 1 },
                  done: { $sum: { $cond: ['$done', 1, 0] } },
                  users: { $addToSet: '$userId' },
                },
              },
              { $sort: { checkins: -1 } },
              { $limit: 20 },
              {
                $lookup: {
                  from: 'habits',
                  localField: '_id',
                  foreignField: '_id',
                  as: 'habit',
                },
              },
              {
                $project: {
                  _id: 0,
                  habitId: '$_id',
                  // Keeps the row when the library entry was deleted; the
                  // admin renders the id instead of dropping real usage.
                  title: { $arrayElemAt: ['$habit.title', 0] },
                  checkins: 1,
                  done: 1,
                  users: { $size: '$users' },
                },
              },
            ],
            notes: [
              {
                $match: {
                  $expr: {
                    $gt: [
                      {
                        $strLenCP: {
                          $trim: { input: { $ifNull: ['$note', ''] } },
                        },
                      },
                      0,
                    ],
                  },
                },
              },
              { $sort: { date: -1 } },
              { $limit: 30 },
              {
                $lookup: {
                  from: 'habits',
                  localField: 'habitId',
                  foreignField: '_id',
                  as: 'habit',
                },
              },
              {
                $project: {
                  _id: 0,
                  userId: 1,
                  habitId: 1,
                  title: { $arrayElemAt: ['$habit.title', 0] },
                  date: 1,
                  note: 1,
                  mood: 1,
                  method: 1,
                  score: 1,
                },
              },
            ],
          },
        },
      ])
      .exec();

    return {
      totals: result?.totals?.[0] ?? null,
      daily: result?.daily ?? [],
      methods: result?.methods ?? [],
      moods: result?.moods ?? [],
      topHabits: result?.topHabits ?? [],
      notes: result?.notes ?? [],
    };
  }

  /**
   * Raw check-in rows for the admin export, newest first.
   *
   * Uses the SAME date window and the same `$unwind` on the user-habit join as
   * [aggregateStatistics], so the file's row sheet and its summary sheet can
   * never disagree about what is in the window — an orphaned check-in is absent
   * from both rather than counted in one.
   *
   * `$sort`/`$limit` run BEFORE the habits lookup: the cap exists to stop a wide
   * window pulling the whole collection into memory, and looking up titles for
   * rows that are about to be dropped would defeat it.
   */
  async listRecords(from?: Date, to?: Date, limit = 20000) {
    const dateMatch: Record<string, Date> = {};
    if (from) dateMatch.$gte = from;
    if (to) dateMatch.$lte = to;

    return this.model
      .aggregate<IHabitCheckinExportRow>([
        ...(Object.keys(dateMatch).length
          ? [{ $match: { date: dateMatch } }]
          : []),
        {
          $lookup: {
            from: 'user_habits',
            localField: 'userHabitId',
            foreignField: '_id',
            as: 'userHabit',
          },
        },
        { $unwind: '$userHabit' },
        { $sort: { date: -1, _id: -1 } },
        { $limit: limit },
        {
          $lookup: {
            from: 'habits',
            localField: 'userHabit.habitId',
            foreignField: '_id',
            as: 'habit',
          },
        },
        {
          $project: {
            _id: 0,
            date: 1,
            done: 1,
            method: { $ifNull: ['$method', HabitCheckinMethod.TAP] },
            mood: 1,
            score: 1,
            note: 1,
            createdAt: 1,
            userId: '$userHabit.userId',
            habitId: '$userHabit.habitId',
            // Kept as the raw translation map; the service picks the locale.
            // Absent when the library entry was deleted — the export then prints
            // the id, the way the statistics screen does.
            habitTitle: { $arrayElemAt: ['$habit.title', 0] },
          },
        },
      ])
      .exec();
  }

  async findDoneDates(userHabitId: string) {
    const docs = await this.model
      .find({ userHabitId, done: true }, { date: 1 })
      .lean();
    return docs.map(d => d.date);
  }

  async findDoneDatesInRange(userHabitId: string, from: Date, to: Date) {
    const docs = await this.model
      .find(
        { userHabitId, done: true, date: { $gte: from, $lte: to } },
        { date: 1 },
      )
      .lean();
    return docs.map(d => d.date);
  }

  async countDone(userHabitId: string) {
    return this.model.countDocuments({ userHabitId, done: true });
  }

  async findTodayForUserHabits(userHabitIds: string[], today: Date) {
    return this.model
      .find({ userHabitId: { $in: userHabitIds }, date: today })
      .lean();
  }

  // Done check-ins for several habits within [from, to] (date-only inclusive)
  // — powers the Weekly recap's "this week" totals and check-in rate.
  async findDoneForUserHabitsInRange(
    userHabitIds: string[],
    from: Date,
    to: Date,
  ) {
    if (!userHabitIds.length) return [];
    return this.model
      .find(
        {
          userHabitId: { $in: userHabitIds },
          done: true,
          date: { $gte: from, $lte: to },
        },
        { userHabitId: 1, date: 1 },
      )
      .lean();
  }

  // Full check-in log for one habit — powers the Habit detail heatmap
  // (done per date) and diary list (mood + note per date). Newest-first.
  async findAllForUserHabit(userHabitId: string, from?: Date, to?: Date) {
    const dateFilter: Record<string, Date> = {};
    if (from) dateFilter.$gte = from;
    if (to) dateFilter.$lte = to;

    return this.model
      .find(
        {
          userHabitId,
          ...(Object.keys(dateFilter).length ? { date: dateFilter } : {}),
        },
        { date: 1, done: 1, note: 1, method: 1, mood: 1, score: 1 },
      )
      .sort({ date: -1 })
      .lean();
  }

  // Check-in log across several habits at once — one query for the admin
  // detail view instead of one per habit. Carries `userHabitId` so the caller
  // can group the rows back onto their habit. Newest-first.
  async findAllForUserHabits(userHabitIds: string[], from?: Date, to?: Date) {
    if (!userHabitIds.length) return [];

    const dateFilter: Record<string, Date> = {};
    if (from) dateFilter.$gte = from;
    if (to) dateFilter.$lte = to;

    return this.model
      .find(
        {
          userHabitId: { $in: userHabitIds },
          ...(Object.keys(dateFilter).length ? { date: dateFilter } : {}),
        },
        {
          userHabitId: 1,
          date: 1,
          done: 1,
          note: 1,
          method: 1,
          mood: 1,
          score: 1,
        },
      )
      .sort({ date: -1 })
      .lean();
  }
}
