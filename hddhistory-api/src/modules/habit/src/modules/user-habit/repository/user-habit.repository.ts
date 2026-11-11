import { Injectable, Logger } from '@nestjs/common';
import { InjectConnection, InjectModel } from '@nestjs/mongoose';
import { Connection, Model, PipelineStage } from 'mongoose';

import { AbstractRepository } from '@base/database/mongodb/abstract.repository';

import { UserHabitState } from '../enum/user-habit.enum';
import { UserHabit } from '../schema/user-habit.schema';

@Injectable()
export class UserHabitRepository extends AbstractRepository<UserHabit> {
  protected readonly logger = new Logger(UserHabitRepository.name);

  constructor(
    @InjectModel(UserHabit.name) model: Model<UserHabit>,
    @InjectConnection() connection: Connection,
  ) {
    super(model, connection);
  }

  async findForUser(userId: string, state?: UserHabitState) {
    return this.model
      .find({ userId, ...(state ? { state } : {}) })
      .sort({ createdAt: 1 })
      .lean();
  }

  /**
   * Habits this user adopted since [since], newest first.
   *
   * The Coach's ① door reads this: "habit mới" in its drawing means added in
   * today's lesson, and the adoption row (written by the app, not the Coach)
   * is the only record of that.
   */
  async findCreatedSince(userId: string, since: Date) {
    return this.model
      .find({ userId, createdAt: { $gte: since } })
      .sort({ createdAt: -1 })
      .lean();
  }

  async countActiveForUser(userId: string) {
    return this.model.countDocuments({
      userId,
      state: UserHabitState.ACTIVE,
    });
  }

  async findOneForUser(id: string, userId: string) {
    return this.model.findOne({ _id: id, userId }).lean();
  }

  /**
   * Admin list: one row per user who has adopted at least one habit, with their
   * habit counts and check-in activity. Not scoped to any caller: the admin
   * route that reaches it is AuthGuard-only (the ADMIN role gate came off — see
   * [UserHabitAdminController]), so nothing below narrows by user.
   */
  async aggregateAdminUserSummaries(opts: {
    page: number;
    take: number;
    search?: string;
    state?: UserHabitState;
  }) {
    const skip = (opts.page - 1) * opts.take;
    const pipeline: PipelineStage[] = [];

    if (opts.state) pipeline.push({ $match: { state: opts.state } });

    pipeline.push(
      {
        $group: {
          _id: '$userId',
          habitCount: { $sum: 1 },
          activeCount: {
            $sum: { $cond: [{ $eq: ['$state', UserHabitState.ACTIVE] }, 1, 0] },
          },
          totalCheckIns: { $sum: { $ifNull: ['$totalCheckIns', 0] } },
          bestStreak: { $max: { $ifNull: ['$bestStreak', 0] } },
          lastCheckInDate: { $max: '$lastCheckInDate' },
          userHabitIds: { $push: '$_id' },
        },
      },
      // `user_habits.userId` is a string but `users._id` is an ObjectId, so this
      // join has to convert. `$convert` with onError/onNull is deliberate: a
      // single malformed userId would otherwise abort the whole aggregation,
      // and guest accounts generate their ids.
      {
        $lookup: {
          from: 'users',
          let: { uid: '$_id' },
          pipeline: [
            {
              $match: {
                $expr: {
                  $eq: [
                    '$_id',
                    {
                      $convert: {
                        input: '$$uid',
                        to: 'objectId',
                        onError: null,
                        onNull: null,
                      },
                    },
                  ],
                },
              },
            },
            { $project: { email: 1, name: 1, role: 1, status: 1 } },
          ],
          as: 'user',
        },
      },
      { $unwind: { path: '$user', preserveNullAndEmptyArrays: true } },
    );

    if (opts.search?.trim()) {
      // Escape first — an unescaped user string would be interpreted as a
      // pattern, so a stray `(` returns a 500 instead of no matches.
      const escaped = opts.search.trim().replace(/[.*+?^${}()|[\]\\]/g, '\\$&');
      const rx = new RegExp(escaped, 'i');
      pipeline.push({
        $match: { $or: [{ 'user.email': rx }, { 'user.name': rx }] },
      });
    }

    pipeline.push(
      {
        $lookup: {
          from: 'habit_checkins',
          let: { ids: '$userHabitIds' },
          pipeline: [
            { $match: { $expr: { $in: ['$userHabitId', '$$ids'] } } },
            {
              $group: {
                _id: null,
                checkinRows: { $sum: 1 },
                doneCount: {
                  $sum: { $cond: [{ $eq: ['$done', true] }, 1, 0] },
                },
                // A note counts only when it is neither missing nor empty —
                // `$cond` treats '' as truthy, so testing `$note` alone would
                // count blank diary entries as journals.
                journalCount: {
                  $sum: {
                    $cond: [{ $ne: [{ $ifNull: ['$note', ''] }, ''] }, 1, 0],
                  },
                },
                quizCount: {
                  $sum: {
                    $cond: [
                      { $ne: [{ $ifNull: ['$score', null] }, null] },
                      1,
                      0,
                    ],
                  },
                },
              },
            },
          ],
          as: 'checkinStats',
        },
      },
      {
        // `$arrayElemAt` rather than `$first` so this keeps working on the
        // older server versions `$first`-as-expression needs 4.4+ for.
        $addFields: {
          checkinRows: {
            $ifNull: [{ $arrayElemAt: ['$checkinStats.checkinRows', 0] }, 0],
          },
          doneCount: {
            $ifNull: [{ $arrayElemAt: ['$checkinStats.doneCount', 0] }, 0],
          },
          journalCount: {
            $ifNull: [{ $arrayElemAt: ['$checkinStats.journalCount', 0] }, 0],
          },
          quizCount: {
            $ifNull: [{ $arrayElemAt: ['$checkinStats.quizCount', 0] }, 0],
          },
        },
      },
      { $project: { checkinStats: 0, userHabitIds: 0 } },
      {
        $facet: {
          // `_id` breaks ties so paging stays stable for users who have never
          // checked in (lastCheckInDate null) and would otherwise sort freely.
          items: [
            { $sort: { lastCheckInDate: -1, _id: 1 } },
            { $skip: skip },
            { $limit: opts.take },
          ],
          total: [{ $count: 'count' }],
        },
      },
    );

    const [result] = await this.model.aggregate(pipeline);
    return {
      items: (result?.items ?? []) as Record<string, any>[],
      total: (result?.total?.[0]?.count ?? 0) as number,
    };
  }

  /**
   * Adoption side of the statistics tab: how many habits are live, and how far
   * people actually get with them.
   *
   * Deliberately NOT filtered by the check-in date window — a habit adopted
   * last month is still active today, and counting only those adopted inside
   * the window would read as "nobody is using habits" on a short range.
   */
  async aggregateAdoption(streakEdges: number[]) {
    const [result] = await this.model
      .aggregate([
        {
          $facet: {
            byState: [
              { $group: { _id: '$state', count: { $sum: 1 } } },
              { $project: { _id: 0, state: '$_id', count: 1 } },
            ],
            streaks: [
              { $match: { bestStreak: { $gte: 1 } } },
              {
                $bucket: {
                  groupBy: '$bestStreak',
                  boundaries: streakEdges,
                  default: 'overflow',
                  output: { count: { $sum: 1 } },
                },
              },
            ],
            users: [
              { $group: { _id: '$userId' } },
              { $count: 'value' },
            ],
          },
        },
      ])
      .exec();

    return {
      byState: result?.byState ?? [],
      streaks: result?.streaks ?? [],
      users: result?.users?.[0]?.value ?? 0,
    };
  }
}
