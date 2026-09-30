import { Injectable, Logger } from '@nestjs/common';
import { InjectConnection, InjectModel } from '@nestjs/mongoose';
import { Connection, Model } from 'mongoose';

import { AbstractRepository } from '@base/database/mongodb/abstract.repository';

import {
  coachAdminWhere,
  ICoachAdminFilter,
  ICoachUserRollup,
} from '../../../shared/coach-admin-filter';
import { CoachSituationAnswer } from '../schema/coach-situation-answer.schema';

@Injectable()
export class CoachSituationAnswerRepository extends AbstractRepository<CoachSituationAnswer> {
  protected readonly logger = new Logger(CoachSituationAnswerRepository.name);

  constructor(
    @InjectModel(CoachSituationAnswer.name)
    model: Model<CoachSituationAnswer>,
    @InjectConnection() connection: Connection,
  ) {
    super(model, connection);
  }

  /**
   * Every situation this reader has answered more than once, with the first and
   * the latest answer — the raw material for ⑤ "ĐỔI THAY".
   *
   * The gap check (three weeks) is a business rule and lives in the service;
   * this returns the pairs and lets the service decide which are far enough
   * apart to be worth showing.
   */
  async findAnswerPairs(userId: string) {
    return this.model.aggregate<{
      _id: string;
      first: { content: string; createdAt: Date };
      latest: { content: string; createdAt: Date };
      count: number;
    }>([
      { $match: { userId } },
      { $sort: { createdAt: 1 } },
      {
        $group: {
          _id: '$situationId',
          first: {
            $first: { content: '$content', createdAt: '$createdAt' },
          },
          latest: {
            $last: { content: '$content', createdAt: '$createdAt' },
          },
          count: { $sum: 1 },
        },
      },
      { $match: { count: { $gte: 2 } } },
    ]);
  }

  /**
   * ④ — one scene whose LATEST answer is old enough to answer again.
   *
   * Oldest first, so a reader with several waits on the one that has waited
   * longest. A scene answered again today drops out on its own: its latest
   * answer is today's.
   */
  async findRetryCandidate(
    userId: string,
    before: Date,
  ): Promise<{ situationId: string; habitId: string | null } | null> {
    const rows = await this.model.aggregate<{
      _id: string;
      latestAt: Date;
      habitId: string | null;
    }>([
      { $match: { userId } },
      { $sort: { createdAt: 1 } },
      {
        $group: {
          _id: '$situationId',
          latestAt: { $last: '$createdAt' },
          habitId: { $last: '$habitId' },
        },
      },
      { $match: { latestAt: { $lte: before } } },
      { $sort: { latestAt: 1 } },
      { $limit: 1 },
    ]);
    const row = rows[0];

    return row ? { situationId: row._id, habitId: row.habitId ?? null } : null;
  }

  /**
   * The scene this reader answered MOST recently — the one they mean by "cảnh
   * cũ" / "tình huống vừa rồi".
   *
   * The mirror of `findRetryCandidate`, and deliberately not a variant of it:
   * ④ wants the one that has waited longest and is gated on three weeks, so it
   * would hand back a scene from last month to somebody asking about yesterday.
   *
   * `habitId` narrows it when the session already knows what it is about; left
   * null it answers across the whole history, because a reader who asks at the
   * coordinator has not picked a habit yet.
   */
  async findLatestAnswered(
    userId: string,
    habitId?: string | null,
  ): Promise<{ situationId: string; habitId: string | null } | null> {
    const rows = await this.model.aggregate<{
      _id: string;
      latestAt: Date;
      habitId: string | null;
    }>([
      { $match: { userId, ...(habitId ? { habitId } : {}) } },
      { $sort: { createdAt: 1 } },
      {
        $group: {
          _id: '$situationId',
          latestAt: { $last: '$createdAt' },
          habitId: { $last: '$habitId' },
        },
      },
      { $sort: { latestAt: -1 } },
      { $limit: 1 },
    ]);
    const row = rows[0];

    return row ? { situationId: row._id, habitId: row.habitId ?? null } : null;
  }

  /**
   * Situations this reader has answered — most recently answered first.
   *
   * Feeds the scene pool: what not to show again, and which one has waited
   * longest when everything has been shown.
   */
  async findAnsweredSituationIds(
    userId: string,
    habitId?: string | null,
  ): Promise<string[]> {
    const rows = await this.model.aggregate<{ _id: string; latestAt: Date }>([
      { $match: { userId, ...(habitId ? { habitId } : {}) } },
      { $group: { _id: '$situationId', latestAt: { $max: '$createdAt' } } },
      { $sort: { latestAt: -1 } },
    ]);

    return rows.map((row) => row._id);
  }

  /**
   * When each habit was last practised IN THE COACH, as habitId → latest
   * answer time. Feeds "đến hạn nhất": a habit practised just now steps to the
   * back of the queue, so three opens in a row stop meeting the same habit.
   */
  async latestAnswerAtByHabit(userId: string): Promise<Map<string, Date>> {
    const rows = await this.model.aggregate<{ _id: string; latestAt: Date }>([
      { $match: { userId, habitId: { $nin: [null, ''] } } },
      { $group: { _id: '$habitId', latestAt: { $max: '$createdAt' } } },
    ]);

    return new Map(rows.map((row) => [String(row._id), row.latestAt]));
  }

  async countBetween(userId: string, from: Date, to: Date): Promise<number> {
    return this.model.countDocuments({
      userId,
      createdAt: { $gte: from, $lte: to },
    });
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
   * Who has written here, and when — the per-user roll-up behind the
   * "Theo user" list. Same filters as the reading list, no cap: see
   * `ICoachUserRollup`.
   */
  async aggregateUsersForAdmin(
    filter: ICoachAdminFilter,
  ): Promise<ICoachUserRollup[]> {
    const rows = await this.model.aggregate<{
      _id: string;
      count: number;
      firstAt: Date;
      lastAt: Date;
    }>([
      { $match: coachAdminWhere(filter) },
      {
        $group: {
          _id: '$userId',
          count: { $sum: 1 },
          firstAt: { $min: '$createdAt' },
          lastAt: { $max: '$createdAt' },
        },
      },
    ]);

    return rows.map((row) => ({
      userId: String(row._id),
      count: row.count,
      firstAt: row.firstAt,
      lastAt: row.lastAt,
    }));
  }
}
