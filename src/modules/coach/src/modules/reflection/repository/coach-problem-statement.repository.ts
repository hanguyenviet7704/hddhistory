import { Injectable, Logger } from '@nestjs/common';
import { InjectConnection, InjectModel } from '@nestjs/mongoose';
import { Connection, Model } from 'mongoose';

import { AbstractRepository } from '@base/database/mongodb/abstract.repository';

import {
  coachAdminWhere,
  ICoachAdminFilter,
  ICoachUserRollup,
} from '../../../shared/coach-admin-filter';
import { CoachProblemStatement } from '../schema/coach-problem-statement.schema';

@Injectable()
export class CoachProblemStatementRepository extends AbstractRepository<CoachProblemStatement> {
  protected readonly logger = new Logger(CoachProblemStatementRepository.name);

  constructor(
    @InjectModel(CoachProblemStatement.name)
    model: Model<CoachProblemStatement>,
    @InjectConnection() connection: Connection,
  ) {
    super(model, connection);
  }

  async findBetween(userId: string, from: Date, to: Date, kind?: string) {
    return this.model
      .find({
        userId,
        createdAt: { $gte: from, $lte: to },
        ...(kind ? { kind } : {}),
      })
      .sort({ createdAt: 1 })
      .lean();
  }

  /**
   * How many rows of one kind the reader has per habit, most first.
   *
   * The course card reads this for `barrier`: a habit somebody has explained
   * stopping at twice is where they are stuck, and that is the one worth
   * pointing a course at.
   */
  async countByHabit(
    userId: string,
    kind: string,
  ): Promise<Array<{ habitId: string; count: number }>> {
    const rows = await this.model.aggregate<{ _id: string; count: number }>([
      { $match: { userId, kind, habitId: { $nin: [null, ''] } } },
      { $group: { _id: '$habitId', count: { $sum: 1 } } },
      { $sort: { count: -1 } },
    ]);

    return rows.map((row) => ({ habitId: String(row._id), count: row.count }));
  }

  /**
   * How many OTHER sessions, since `since`, filed a line about one habit.
   *
   * Distinct sessions, not rows: one evening in which the reader wrote three
   * sentences about the same thing is one evening. Only the kinds that are a
   * telling — the problem sentence and the quick jot — count; a barrier is
   * about a commitment, and 6b's "hôm đó bạn làm gì" is about an invented
   * scene. This is what lets the Coach say "lần thứ ba trong tháng" and be
   * stating a fact from the reader's own rows rather than an impression.
   */
  async countSessionsAboutHabit(params: {
    userId: string;
    habitId: string;
    since: Date;
    exceptSessionId: string;
    kinds: string[];
  }): Promise<number> {
    const rows = await this.model.aggregate<{ _id: string }>([
      {
        $match: {
          userId: params.userId,
          habitId: params.habitId,
          kind: { $in: params.kinds },
          sessionId: { $ne: params.exceptSessionId },
          createdAt: { $gte: params.since },
        },
      },
      { $group: { _id: '$sessionId' } },
    ]);

    return rows.length;
  }

  /**
   * The admin reading list: a window, optional filters, newest first, capped.
   *
   * Capped rather than paginated for the same reason `CoachRatingRepository`
   * does it — this is a person reading what people wrote, not a dataset export.
   * The cap is per source, and the caller merges: see `CoachContentService`.
   */
  async findForAdmin(filter: ICoachAdminFilter & { limit: number }) {
    return this.model
      .find(coachAdminWhere(filter))
      .sort({ createdAt: -1 })
      .limit(filter.limit)
      .lean();
  }

  /**
   * The per-user roll-up, split by `kind`.
   *
   * The only one of the four sources that holds more than one kind — three of
   * the six live here — so it groups by the pair and lets the service decide
   * which of them the caller asked for.
   */
  async aggregateUsersForAdmin(
    filter: ICoachAdminFilter,
  ): Promise<Array<ICoachUserRollup & { kind: string | null }>> {
    const rows = await this.model.aggregate<{
      _id: { userId: string; kind: string | null };
      count: number;
      firstAt: Date;
      lastAt: Date;
    }>([
      { $match: coachAdminWhere(filter) },
      {
        $group: {
          _id: { userId: '$userId', kind: '$kind' },
          count: { $sum: 1 },
          firstAt: { $min: '$createdAt' },
          lastAt: { $max: '$createdAt' },
        },
      },
    ]);

    return rows.map((row) => ({
      userId: String(row._id.userId),
      kind: row._id.kind ?? null,
      count: row.count,
      firstAt: row.firstAt,
      lastAt: row.lastAt,
    }));
  }
}
