import { Injectable, Logger } from '@nestjs/common';
import { InjectConnection, InjectModel } from '@nestjs/mongoose';
import { Connection, Model } from 'mongoose';

import { AbstractRepository } from '@base/database/mongodb/abstract.repository';

import { RecentlyViewedCourse } from './schema/recently-viewed-course.schema';

const MAX_RECENT = 10;

@Injectable()
export class RecentlyViewedRepository extends AbstractRepository<RecentlyViewedCourse> {
  protected readonly logger = new Logger(RecentlyViewedRepository.name);

  constructor(
    @InjectModel(RecentlyViewedCourse.name)
    model: Model<RecentlyViewedCourse>,
    @InjectConnection() connection: Connection,
  ) {
    super(model, connection);
  }

  async upsertView(userId: string, courseId: string): Promise<void> {
    await this.model.findOneAndUpdate(
      { userId, courseId },
      { $set: { userId, courseId, updatedAt: new Date() } },
      { upsert: true, new: true },
    );

    // Keep only the MAX_RECENT most-recent entries per user.
    const all = await this.model
      .find({ userId })
      .sort({ updatedAt: -1 })
      .select('_id')
      .lean();

    if (all.length > MAX_RECENT) {
      const toDelete = all.slice(MAX_RECENT).map(d => d._id);
      await this.model.deleteMany({ _id: { $in: toDelete } });
    }
  }

  /** Returns recent course ids for the user, most-recent first (max 10). */
  async getRecentCourseIds(userId: string): Promise<string[]> {
    const docs = await this.model
      .find({ userId })
      .sort({ updatedAt: -1 })
      .limit(MAX_RECENT)
      .select('courseId')
      .lean();

    return docs.map(d => d.courseId);
  }

  /**
   * The courses most people opened since [since], most-opened first.
   *
   * One row per (user, course) by unique index, so counting rows counts
   * DISTINCT USERS — a single reader reopening a course fifty times still
   * contributes one. That is the number the strip claims ("N người học") and
   * the one that is hardest for a handful of readers to skew.
   *
   * Bounded by `upsertView`'s prune: only a user's 10 most recent rows survive,
   * so a reader who opened more than ten courses inside the window loses their
   * earliest ones. The prune keeps the NEWEST rows and this query asks about
   * the NEWEST week, so the overlap is what matters; the undercount lands only
   * on courses opened early in the week by very heavy browsers.
   */
  async aggregateTopOpenedSince(
    since: Date,
    limit: number,
  ): Promise<{ courseId: string; learnerCount: number }[]> {
    const rows = await this.model.aggregate<{
      _id: string;
      learnerCount: number;
    }>([
      { $match: { updatedAt: { $gte: since } } },
      { $group: { _id: '$courseId', learnerCount: { $sum: 1 } } },
      { $sort: { learnerCount: -1, _id: 1 } },
      { $limit: limit },
    ]);

    return rows.map(r => ({ courseId: r._id, learnerCount: r.learnerCount }));
  }

  async clearAll(userId: string): Promise<void> {
    await this.model.deleteMany({ userId });
  }
}
