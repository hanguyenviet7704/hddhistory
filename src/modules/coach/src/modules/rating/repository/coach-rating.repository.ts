import { Injectable, Logger } from '@nestjs/common';
import { InjectConnection, InjectModel } from '@nestjs/mongoose';
import { Connection, Model } from 'mongoose';

import { AbstractRepository } from '@base/database/mongodb/abstract.repository';

import { CoachRatingSource, CoachSessionKind } from '../enum/rating.enum';
import { CoachRating } from '../schema/coach-rating.schema';

@Injectable()
export class CoachRatingRepository extends AbstractRepository<CoachRating> {
  protected readonly logger = new Logger(CoachRatingRepository.name);

  constructor(
    @InjectModel(CoachRating.name) model: Model<CoachRating>,
    @InjectConnection() connection: Connection,
  ) {
    super(model, connection);
  }

  /**
   * The admin list.
   *
   * Newest first and capped: this is a reading list for a person, not a
   * dataset. Nothing is sampled — the volume is low and the whole point is that
   * somebody reads all of it.
   *
   * `to` is pushed to the end of its day so a date picker's "14/09" means the
   * whole of the 14th rather than its first instant, which would return an
   * empty list for today every time.
   */
  async findForAdmin(filter: {
    needsReview?: boolean;
    source?: CoachRatingSource;
    sessionKind?: CoachSessionKind;
    from?: string;
    to?: string;
  }) {
    const where: Record<string, unknown> = {};
    if (filter.needsReview !== undefined) where.needsReview = filter.needsReview;
    if (filter.source) where.source = filter.source;
    if (filter.sessionKind) where.sessionKind = filter.sessionKind;

    const createdAt: Record<string, Date> = {};
    if (filter.from) createdAt.$gte = new Date(filter.from);
    if (filter.to) {
      const end = new Date(filter.to);
      end.setHours(23, 59, 59, 999);
      createdAt.$lte = end;
    }
    if (Object.keys(createdAt).length) where.createdAt = createdAt;

    return this.model.find(where).sort({ createdAt: -1 }).limit(500).lean();
  }

  async markReviewed(id: string) {
    return this.model
      .findOneAndUpdate({ _id: id }, { $set: { needsReview: false } }, { new: true })
      .lean();
  }
}
