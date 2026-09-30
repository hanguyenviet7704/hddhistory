import { Injectable, Logger } from '@nestjs/common';
import { InjectConnection, InjectModel } from '@nestjs/mongoose';
import { Connection, Model } from 'mongoose';

import { AbstractRepository } from '@base/database/mongodb/abstract.repository';

import { CoachMetricKind } from '../enum/coach-metric.enum';
import { CoachMetric } from '../schema/coach-metric.schema';

@Injectable()
export class CoachMetricRepository extends AbstractRepository<CoachMetric> {
  protected readonly logger = new Logger(CoachMetricRepository.name);

  constructor(
    @InjectModel(CoachMetric.name) model: Model<CoachMetric>,
    @InjectConnection() connection: Connection,
  ) {
    super(model, connection);
  }

  /** Upsert-and-increment. The unique index makes concurrent bumps safe. */
  async bump(kind: CoachMetricKind, isoWeek: string, refId: string | null) {
    return this.model.updateOne(
      { kind, refId, isoWeek },
      { $inc: { count: 1 }, $setOnInsert: { kind, refId, isoWeek } },
      { upsert: true },
    );
  }

  async findByWeek(isoWeek: string) {
    return this.model.find({ isoWeek }).lean();
  }

  /**
   * Weeks that actually hold counts, newest first.
   *
   * The admin week picker is built from this rather than from a date range: the
   * counters only exist for weeks the Coach ran in, and offering an empty week
   * would look like the feature broke that week rather than never ran.
   */
  async distinctWeeks(limit: number): Promise<string[]> {
    const rows = await this.model.aggregate([
      { $group: { _id: '$isoWeek' } },
      { $sort: { _id: -1 } },
      { $limit: limit },
    ]);

    return rows.map((row) => String(row._id));
  }
}
