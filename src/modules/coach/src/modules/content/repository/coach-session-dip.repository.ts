import { Injectable, Logger } from '@nestjs/common';
import { InjectConnection, InjectModel } from '@nestjs/mongoose';
import { Connection, Model } from 'mongoose';

import { AbstractRepository } from '@base/database/mongodb/abstract.repository';

import {
  coachAdminWhere,
  ICoachAdminFilter,
  ICoachUserRollup,
} from '../../../shared/coach-admin-filter';
import { CoachSession } from '../../session/schema/coach-session.schema';

/**
 * Sessions with no dip are the majority — most never reach T4 — so the
 * emptiness check is part of the query rather than a filter after the fact.
 */
const DIP_EXISTS = { dip: { $nin: [null, ''] } };

/**
 * The ADMIN read of `coach_sessions`: the `dip` field, and the transcript.
 *
 * A repository of its own rather than methods on the session repository,
 * because that one is on the hot path of every turn — the two have nothing to
 * share but a collection name.
 *
 * Both reads are bounded by `COACH_SESSION_TTL_HOURS`: Mongo deletes the whole
 * document on `expiresAt`, so neither can answer for a session older than that
 * however wide a date range is asked for.
 */
@Injectable()
export class CoachSessionDipRepository extends AbstractRepository<CoachSession> {
  protected readonly logger = new Logger(CoachSessionDipRepository.name);

  constructor(
    @InjectModel(CoachSession.name) model: Model<CoachSession>,
    @InjectConnection() connection: Connection,
  ) {
    super(model, connection);
  }

  async findDipsForAdmin(filter: ICoachAdminFilter & { limit: number }) {
    return this.model
      .find(coachAdminWhere(filter, { textField: 'dip', base: DIP_EXISTS }))
      .select({ userId: 1, habitId: 1, dip: 1, createdAt: 1 })
      .sort({ createdAt: -1 })
      .limit(filter.limit)
      .lean();
  }

  /**
   * The per-user roll-up of dips.
   *
   * Reads a TTL'd collection, so it answers for the last
   * `COACH_SESSION_TTL_HOURS` and no further back — a reader who typed a dozen
   * dips last month counts zero here. The screen says so; see the note on
   * `CoachContentKind.DIP`.
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
      { $match: coachAdminWhere(filter, { textField: 'dip', base: DIP_EXISTS }) },
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

  /**
   * The sessions themselves, oldest first, for the admin thread.
   *
   * `turns` is the only place a Coach line is ever written, so this is what
   * makes a real transcript possible at all. Ordered ascending because a
   * conversation is read forwards; the reading list elsewhere is the opposite
   * for the opposite reason.
   */
  async findSessionsForAdmin(filter: {
    userId: string;
    from?: Date;
    to?: Date;
    limit: number;
  }) {
    const where: Record<string, unknown> = { userId: filter.userId };
    if (filter.from || filter.to) {
      where.createdAt = {
        ...(filter.from ? { $gte: filter.from } : {}),
        ...(filter.to ? { $lte: filter.to } : {}),
      };
    }

    return this.model
      .find(where)
      .select({
        userId: 1,
        entry: 1,
        tier: 1,
        habitId: 1,
        step: 1,
        status: 1,
        turns: 1,
        dip: 1,
        createdAt: 1,
        closedAt: 1,
      })
      .sort({ createdAt: 1 })
      .limit(filter.limit)
      .lean();
  }

  /**
   * Wipes the dip a reader typed, leaving the session itself alone.
   *
   * `$unset` rather than a delete, and rather than `AbstractRepository.updateOne`
   * which can only set fields: the document is a whole session — turns, habit,
   * status — and the dip is one field on it. Deleting the session to remove one
   * sentence would take the transcript with it.
   *
   * Matching on `DIP_EXISTS` makes "no dip to clear" and "already cleared"
   * arrive as `modifiedCount: 0` rather than as a silent success.
   */
  async clearDip(sessionId: string) {
    return this.model.updateOne(
      { _id: sessionId, ...DIP_EXISTS },
      { $unset: { dip: 1 } },
    );
  }
}
