import { Injectable, Logger } from '@nestjs/common';
import { InjectConnection, InjectModel } from '@nestjs/mongoose';
import { Connection, Model } from 'mongoose';

import { AbstractRepository } from '@base/database/mongodb/abstract.repository';

import {
  coachAdminWhere,
  ICoachAdminFilter,
  ICoachUserRollup,
} from '../../../shared/coach-admin-filter';
import { CoachEvidence } from '../schema/coach-evidence.schema';

@Injectable()
export class CoachEvidenceRepository extends AbstractRepository<CoachEvidence> {
  protected readonly logger = new Logger(CoachEvidenceRepository.name);

  constructor(
    @InjectModel(CoachEvidence.name) model: Model<CoachEvidence>,
    @InjectConnection() connection: Connection,
  ) {
    super(model, connection);
  }

  /** ⑤ "ĐỜI THẬT" — what actually happened out there, this week. */
  async findBetween(userId: string, from: Date, to: Date) {
    return this.model
      .find({ userId, createdAt: { $gte: from, $lte: to } })
      .sort({ createdAt: 1 })
      .lean();
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
