import { Injectable } from '@nestjs/common';
import { InjectConnection, InjectModel } from '@nestjs/mongoose';
import { Connection, FilterQuery, Model } from 'mongoose';

import { AbstractRepository } from '@base/database/mongodb/abstract.repository';
import { IResponseListPage } from '@utils/interface/paging/page.interface';
import { OrderType } from '@utils/type/orderByType';

import { ImportJobStatus } from '../enum/learning-import.enum';
import { LearningImportJob } from '../schema/learning-import-job.schema';

@Injectable()
export class LearningImportJobRepository extends AbstractRepository<LearningImportJob> {
  constructor(
    @InjectModel(LearningImportJob.name) model: Model<LearningImportJob>,
    @InjectConnection() connection: Connection,
  ) {
    super(model, connection);
  }

  /**
   * One job, but only if it belongs to `userId`.
   *
   * Ownership is enforced HERE rather than in the service, so a future caller
   * cannot forget to pass the filter and hand one user another user's import.
   * Same shape as `CourseImportJobRepository.findOwnedJob`.
   */
  async findOwnedJob(
    jobId: string,
    userId: string,
  ): Promise<LearningImportJob | null> {
    return this.model.findOne({ _id: jobId, userId }).lean<LearningImportJob>();
  }

  async findAnyJob(jobId: string): Promise<LearningImportJob | null> {
    return this.model.findById(jobId).lean<LearningImportJob>();
  }

  /**
   * The user's in-flight job, if any -- the single-flight check behind
   * JOB_ALREADY_RUNNING.
   *
   * `staleBefore` is what stops a run killed by a deploy from blocking the user
   * forever: a PROCESSING document whose heartbeat has gone quiet is treated as
   * dead and does not count as in flight, exactly as the read path reports it
   * as INTERRUPTED.
   */
  async findActiveByUser(
    userId: string,
    staleBefore: Date,
  ): Promise<LearningImportJob | null> {
    return this.model
      .findOne({
        userId,
        $or: [
          { status: ImportJobStatus.QUEUED },
          {
            status: ImportJobStatus.PROCESSING,
            heartbeatAt: { $gte: staleBefore },
          },
        ],
      })
      .lean<LearningImportJob>();
  }

  /**
   * How many slots the user has spent in the window.
   *
   * Counted rather than kept in a counter field: with one source of truth there
   * is nothing to drift, and a job flipped to `countsTowardQuota: false` on
   * failure refunds itself with no compensating write.
   */
  async countChargedInRange(
    userId: string,
    from: Date,
    to: Date,
  ): Promise<number> {
    return this.model.countDocuments({
      userId,
      countsTowardQuota: true,
      createdAt: { $gte: from, $lt: to },
    });
  }

  /**
   * How many slots the user has spent EVER.
   *
   * The free tier's allowance is a lifetime one, so its balance cannot be read
   * from a window: a reader who spent their free ticket in March must still be at
   * zero in April. Same `countsTowardQuota` filter as the windowed count above,
   * so a failed run refunds itself here too.
   */
  async countChargedAllTime(userId: string): Promise<number> {
    return this.model.countDocuments({ userId, countsTowardQuota: true });
  }

  /**
   * Everything the admin panel's stat row needs, in ONE round trip.
   *
   * A `$facet` rather than six queries: they all scan the same collection, and
   * six sequential awaits on a growing collection is how an admin page starts
   * taking two seconds to draw a handful of numbers.
   *
   * Money is summed from `usage.estimatedCostVnd`, which the runner writes as an
   * ESTIMATE (see its own note) -- so this is a scale, not an invoice.
   */
  async aggregateStats(since: Date): Promise<{
    totalJobs: number;
    jobsLast7Days: number;
    uniqueUsers: number;
    totalCostVnd: number;
    chargedJobs: number;
    totalLessons: number;
    byStatus: Array<{ status: string; count: number }>;
    bySource: Array<{ sourceType: string; count: number }>;
    topErrors: Array<{ code: string; count: number }>;
  }> {
    const [result] = await this.model
      .aggregate([
        {
          $facet: {
            total: [{ $count: 'count' }],
            recent: [{ $match: { createdAt: { $gte: since } } }, { $count: 'count' }],
            users: [{ $group: { _id: '$userId' } }, { $count: 'count' }],
            cost: [
              { $match: { 'usage.estimatedCostVnd': { $gt: 0 } } },
              {
                $group: {
                  _id: null,
                  total: { $sum: '$usage.estimatedCostVnd' },
                  jobs: { $sum: 1 },
                },
              },
            ],
            lessons: [
              { $match: { userLessonId: { $nin: [null, ''] } } },
              { $count: 'count' },
            ],
            byStatus: [
              { $group: { _id: '$status', count: { $sum: 1 } } },
              { $sort: { count: -1 } },
            ],
            bySource: [
              { $group: { _id: '$sourceType', count: { $sum: 1 } } },
              { $sort: { count: -1 } },
            ],
            // Only real failures carry a code, so this needs no status filter --
            // and an unnamed failure is still worth counting, hence the fallback.
            topErrors: [
              { $match: { 'error.code': { $nin: [null, ''] } } },
              { $group: { _id: '$error.code', count: { $sum: 1 } } },
              { $sort: { count: -1 } },
              { $limit: 5 },
            ],
          },
        },
      ])
      .exec();

    const first = (rows: Array<{ count?: number }> = []) => rows[0]?.count ?? 0;

    return {
      totalJobs: first(result?.total),
      jobsLast7Days: first(result?.recent),
      uniqueUsers: first(result?.users),
      totalCostVnd: result?.cost?.[0]?.total ?? 0,
      chargedJobs: result?.cost?.[0]?.jobs ?? 0,
      totalLessons: first(result?.lessons),
      byStatus: (result?.byStatus ?? []).map((row: any) => ({
        status: String(row._id ?? 'unknown'),
        count: row.count ?? 0,
      })),
      bySource: (result?.bySource ?? []).map((row: any) => ({
        sourceType: String(row._id ?? 'unknown'),
        count: row.count ?? 0,
      })),
      topErrors: (result?.topErrors ?? []).map((row: any) => ({
        code: String(row._id ?? 'UNKNOWN'),
        count: row.count ?? 0,
      })),
    };
  }

  async patch(
    jobId: string,
    data: Partial<LearningImportJob>,
  ): Promise<void> {
    await this.model.updateOne({ _id: jobId }, { $set: data });
  }

  async findPaginatedByUser(
    userId: string,
    page: number,
    take: number,
  ): Promise<IResponseListPage<LearningImportJob>> {
    return this.paginateQuery<LearningImportJob>({
      where: { userId },
      orderBy: 'createdAt',
      order: OrderType.DESC,
      page,
      take,
    });
  }

  // Admin feed: every user's imports, newest first, optionally narrowed by
  // status or by a search over the source name/URL.
  async findPaginatedForAdmin(params: {
    page: number;
    take: number;
    status?: ImportJobStatus;
    search?: string;
  }): Promise<IResponseListPage<LearningImportJob>> {
    const where: FilterQuery<LearningImportJob> = {};

    if (params.status) where.status = params.status;

    if (params.search) {
      // Escaped before it reaches the regex: an unescaped user string here is
      // both a crash (unbalanced bracket) and a way to pin the collection scan.
      const safe = params.search.replace(/[.*+?^${}()|[\]\\]/g, '\\$&');
      const pattern = new RegExp(safe, 'i');
      where.$or = [
        { 'source.fileName': pattern },
        { 'source.url': pattern },
        { 'source.videoTitle': pattern },
      ];
    }

    return this.paginateQuery<LearningImportJob>({
      where,
      orderBy: 'createdAt',
      order: OrderType.DESC,
      page: params.page,
      take: params.take,
    });
  }
}
