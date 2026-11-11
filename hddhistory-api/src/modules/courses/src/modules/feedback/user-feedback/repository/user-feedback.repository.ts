import { Injectable, Logger } from '@nestjs/common';
import { InjectConnection, InjectModel } from '@nestjs/mongoose';
import { Connection, Model, PipelineStage, UpdateQuery } from 'mongoose';

import { AbstractRepository } from '@base/database/mongodb/abstract.repository';

import { FeedbackEntry, FeedbackType } from '../enum/user-feedback.enum';
import {
  IUserFeedbackDistributions,
  IUserFeedbackMetricsRow,
  IUserFeedbackRecord,
  IUserFeedbackStatisticsFilter,
} from '../interface/user-feedback.interface';
import { UserFeedback } from '../schema/user-feedback.schema';

@Injectable()
export class UserFeedbackRepository extends AbstractRepository<UserFeedback> {
  protected readonly logger = new Logger(UserFeedbackRepository.name);

  constructor(
    @InjectModel(UserFeedback.name) model: Model<UserFeedback>,
    @InjectConnection() connection: Connection,
  ) {
    super(model, connection);
  }

  async upsertByUserId(userId: string, update: UpdateQuery<UserFeedback>) {
    return this.model
      .findOneAndUpdate({ userId }, update, {
        upsert: true,
        new: true,
        setDefaultsOnInsert: true,
      })
      .lean();
  }

  async findByUserId(userId: string) {
    return this.model.findOne({ userId }).lean();
  }

  /**
   * Turns one document (four optional embedded slots) into up to four FLAT
   * records, then filters them.
   *
   * This exists because the collection has no top-level submission date,
   * entry or type: those live inside `keypointComplete` / `keypointIncomplete`
   * / `roleplayComplete` / `roleplayIncomplete`. Every statistic below is a
   * count over slots, not over documents, so each one would otherwise need its
   * own four-branch `$or` and its own reshaping. Normalising once up front is
   * what keeps the facets readable.
   *
   * `$ifNull` before `$filter` is deliberate: a missing field inside an array
   * literal does NOT become null on its own, so an absent slot would survive
   * the filter and unwind into a record with no data.
   */
  private buildNormalizeStages(
    filter: IUserFeedbackStatisticsFilter,
  ): PipelineStage[] {
    const match: Record<string, any> = {};
    if (filter.entry) match.entry = filter.entry;
    if (filter.type) match.type = filter.type;
    if (filter.startDate || filter.endDate) {
      match.submittedAt = {};
      if (filter.startDate) match.submittedAt.$gte = filter.startDate;
      if (filter.endDate) match.submittedAt.$lte = filter.endDate;
    }

    return [
      {
        $project: {
          userId: 1,
          slots: {
            $filter: {
              input: [
                {
                  entry: FeedbackEntry.KEYPOINT,
                  type: FeedbackType.COMPLETE,
                  data: { $ifNull: ['$keypointComplete', null] },
                },
                {
                  entry: FeedbackEntry.KEYPOINT,
                  type: FeedbackType.INCOMPLETE,
                  data: { $ifNull: ['$keypointIncomplete', null] },
                },
                {
                  entry: FeedbackEntry.ROLEPLAY,
                  type: FeedbackType.COMPLETE,
                  data: { $ifNull: ['$roleplayComplete', null] },
                },
                {
                  entry: FeedbackEntry.ROLEPLAY,
                  type: FeedbackType.INCOMPLETE,
                  data: { $ifNull: ['$roleplayIncomplete', null] },
                },
              ],
              as: 'slot',
              cond: { $ne: ['$$slot.data', null] },
            },
          },
        },
      },
      { $unwind: '$slots' },
      {
        $project: {
          _id: 0,
          userId: 1,
          entry: '$slots.entry',
          type: '$slots.type',
          courseId: '$slots.data.courseId',
          courseTitle: '$slots.data.courseTitle',
          lessonId: '$slots.data.lessonId',
          lessonTitle: '$slots.data.lessonTitle',
          keypointId: '$slots.data.keypointId',
          keypointTitle: '$slots.data.keypointTitle',
          reasons: { $ifNull: ['$slots.data.reasons', []] },
          overallRating: '$slots.data.overallRating',
          contentRating: '$slots.data.contentRating',
          experienceRating: '$slots.data.experienceRating',
          comment: '$slots.data.comment',
          submittedAt: '$slots.data.submittedAt',
        },
      },
      { $match: match },
    ];
  }

  /**
   * Headline numbers for one date window. Called twice by the service (current
   * and previous window) so the UI can show a delta.
   *
   * `users` counts DISTINCT users, and it is not the same as `records`: one
   * user can hold up to four slots. The admin screen leans on that difference.
   */
  async aggregateMetrics(
    filter: IUserFeedbackStatisticsFilter,
  ): Promise<IUserFeedbackMetricsRow | null> {
    const [result] = await this.model
      .aggregate<IUserFeedbackMetricsRow>([
        ...this.buildNormalizeStages(filter),
        {
          $group: {
            _id: null,
            records: { $sum: 1 },
            users: { $addToSet: '$userId' },
            complete: {
              $sum: { $cond: [{ $eq: ['$type', FeedbackType.COMPLETE] }, 1, 0] },
            },
            incomplete: {
              $sum: {
                $cond: [{ $eq: ['$type', FeedbackType.INCOMPLETE] }, 1, 0],
              },
            },
            keypoint: {
              $sum: { $cond: [{ $eq: ['$entry', FeedbackEntry.KEYPOINT] }, 1, 0] },
            },
            roleplay: {
              $sum: { $cond: [{ $eq: ['$entry', FeedbackEntry.ROLEPLAY] }, 1, 0] },
            },
            withComment: {
              $sum: {
                $cond: [
                  {
                    $gt: [
                      {
                        $strLenCP: {
                          $trim: { input: { $ifNull: ['$comment', ''] } },
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
            // A rating below 1 is NOT a score, it is "unrated": the client
            // submits 0 when the reader skipped the stars (the schema's
            // `min: 1` never fires because the upsert `$set`s a subdocument,
            // which skips validation). Averaging those zeros in dragged the
            // overall score to 1.3 while content/experience sat at 4.2 —
            // $avg ignores null, so map them to null instead of counting them.
            averageOverall: {
              $avg: {
                $cond: [{ $gte: ['$overallRating', 1] }, '$overallRating', null],
              },
            },
            averageContent: {
              $avg: {
                $cond: [{ $gte: ['$contentRating', 1] }, '$contentRating', null],
              },
            },
            averageExperience: {
              $avg: {
                $cond: [
                  { $gte: ['$experienceRating', 1] },
                  '$experienceRating',
                  null,
                ],
              },
            },
            // How many complete feedbacks arrived with no star rating at all —
            // worth showing rather than silently dropping.
            unrated: {
              $sum: {
                $cond: [
                  {
                    $and: [
                      { $eq: ['$type', FeedbackType.COMPLETE] },
                      { $not: [{ $gte: ['$overallRating', 1] }] },
                    ],
                  },
                  1,
                  0,
                ],
              },
            },
          },
        },
        {
          $project: {
            _id: 0,
            records: 1,
            users: { $size: '$users' },
            complete: 1,
            incomplete: 1,
            keypoint: 1,
            roleplay: 1,
            withComment: 1,
            averageOverall: 1,
            averageContent: 1,
            averageExperience: 1,
            unrated: 1,
          },
        },
      ])
      .exec();

    return result ?? null;
  }

  /**
   * The three distributions the screen draws, in one round trip.
   *
   * Reasons are only meaningful for incomplete feedback and ratings only for
   * complete feedback, so each facet re-filters rather than trusting the
   * caller's `type` filter.
   */
  async aggregateDistributions(
    filter: IUserFeedbackStatisticsFilter,
  ): Promise<IUserFeedbackDistributions> {
    const [result] = await this.model
      .aggregate<IUserFeedbackDistributions>([
        ...this.buildNormalizeStages(filter),
        {
          $facet: {
            reasons: [
              { $match: { type: FeedbackType.INCOMPLETE } },
              { $unwind: '$reasons' },
              { $group: { _id: '$reasons', count: { $sum: 1 } } },
              { $project: { _id: 0, reason: '$_id', count: 1 } },
              { $sort: { count: -1 } },
            ],
            ratings: [
              { $match: { type: FeedbackType.COMPLETE, overallRating: { $gte: 1 } } },
              { $group: { _id: '$overallRating', count: { $sum: 1 } } },
              { $project: { _id: 0, rating: '$_id', count: 1 } },
              { $sort: { rating: 1 } },
            ],
            // "Which content did people walk away from" — grouped by keypoint
            // when there is one, else by the lesson (roleplay carries no
            // keypointId).
            topAbandoned: [
              { $match: { type: FeedbackType.INCOMPLETE } },
              {
                $group: {
                  _id: {
                    entry: '$entry',
                    courseId: '$courseId',
                    lessonId: '$lessonId',
                    keypointId: '$keypointId',
                  },
                  count: { $sum: 1 },
                  courseTitle: { $first: '$courseTitle' },
                  lessonTitle: { $first: '$lessonTitle' },
                  keypointTitle: { $first: '$keypointTitle' },
                  reasons: { $push: '$reasons' },
                },
              },
              {
                $project: {
                  _id: 0,
                  entry: '$_id.entry',
                  courseId: '$_id.courseId',
                  lessonId: '$_id.lessonId',
                  keypointId: '$_id.keypointId',
                  courseTitle: 1,
                  lessonTitle: 1,
                  keypointTitle: 1,
                  count: 1,
                  // $concatArrays, not $setUnion: the union collapsed to "all
                  // five reasons" on every busy row, which is true and useless.
                  // Keeping duplicates lets the service rank them.
                  reasons: {
                    $reduce: {
                      input: '$reasons',
                      initialValue: [],
                      in: { $concatArrays: ['$$value', '$$this'] },
                    },
                  },
                },
              },
              { $sort: { count: -1 } },
              { $limit: 20 },
            ],
          },
        },
      ])
      .exec();

    return {
      reasons: result?.reasons ?? [],
      ratings: result?.ratings ?? [],
      topAbandoned: result?.topAbandoned ?? [],
    };
  }

  /**
   * Feedback that carries written text, newest first — the part an admin
   * actually reads. Paginated because a comment list has no natural ceiling.
   */
  async aggregateComments(
    filter: IUserFeedbackStatisticsFilter,
    page: number,
    take: number,
  ): Promise<{ items: IUserFeedbackRecord[]; total: number }> {
    const [result] = await this.model
      .aggregate<{ items: IUserFeedbackRecord[]; total: { value: number }[] }>([
        ...this.buildNormalizeStages(filter),
        // $trim, not just `$nin: [null, '']`: real rows carry a bare "\n" from
        // the app's textarea, which passed the plain check and rendered as an
        // empty comment card.
        {
          $match: {
            $expr: {
              $gt: [
                {
                  $strLenCP: { $trim: { input: { $ifNull: ['$comment', ''] } } },
                },
                0,
              ],
            },
          },
        },
        {
          $facet: {
            items: [
              { $sort: { submittedAt: -1 } },
              { $skip: (page - 1) * take },
              { $limit: take },
            ],
            total: [{ $count: 'value' }],
          },
        },
      ])
      .exec();

    return {
      items: result?.items ?? [],
      total: result?.total?.[0]?.value ?? 0,
    };
  }

  /**
   * Every filtered record, flat, for the Excel export.
   *
   * Capped: an export is a file someone waits on, and an unbounded $sort over
   * a growing collection is how that turns into a timeout. The service tells
   * the reader when the cap was hit rather than handing over a silently short
   * file.
   */
  async listRecords(
    filter: IUserFeedbackStatisticsFilter,
    limit: number,
  ): Promise<IUserFeedbackRecord[]> {
    return this.model
      .aggregate<IUserFeedbackRecord>([
        ...this.buildNormalizeStages(filter),
        { $sort: { submittedAt: -1 } },
        { $limit: limit },
      ])
      .exec();
  }

  getFeedbackCursor(batchSize: number) {
    return this.model
      .find(
        {},
        {
          userId: 1,
          roleplayComplete: 1,
          roleplayIncomplete: 1,
          keypointComplete: 1,
          keypointIncomplete: 1,
          createdAt: 1,
          updatedAt: 1,
        },
      )
      .lean()
      .cursor({ batchSize });
  }

  /**
   * CSAT của một khoá trong các cửa sổ thời gian mà một tag đang được phục vụ
   * — cột "Đánh giá CSAT" của bảng so sánh phiên bản.
   *
   * Gán theo thời gian gửi phản hồi, vì bản thân phản hồi không mang tag. Hai
   * giới hạn phải nhớ khi đọc con số này:
   *
   *  - Collection này **upsert theo `userId`**, mỗi người giữ nhiều nhất một
   *    slot mỗi loại. Người phản hồi khoá khác sau đó sẽ ghi đè, nên đây là
   *    "phản hồi gần nhất của mỗi người, lọc theo khoá" chứ không phải toàn bộ
   *    phản hồi từng gửi. Thưa, và thưa dần theo thời gian.
   *  - `contentRating` bằng 0 nghĩa là gửi mà không chấm sao, nên phải loại —
   *    tính cả nhóm này vào thì mọi bản đều bị kéo về 0 như nhau và cột trở
   *    nên vô dụng.
   *
   * Lấy `contentRating` chứ không `overallRating`: A/B ở đây là A/B NỘI DUNG.
   */
  async averageContentRatingInWindows(params: {
    courseId: string;
    windows: { from: Date; to?: Date | null }[];
    now?: Date;
  }): Promise<{ average: number | null; responses: number }> {
    if (!params.windows.length) return { average: null, responses: 0 };

    const now = params.now ?? new Date();
    const rows = await this.model.aggregate<{ avg: number; count: number }>([
      ...this.buildNormalizeStages({}),
      {
        $match: {
          courseId: params.courseId,
          contentRating: { $gt: 0 },
          $or: params.windows.map(w => ({
            submittedAt: { $gte: w.from, $lte: w.to ?? now },
          })),
        },
      },
      {
        $group: {
          _id: null,
          avg: { $avg: '$contentRating' },
          count: { $sum: 1 },
        },
      },
    ]);

    const row = rows[0];
    if (!row?.count) return { average: null, responses: 0 };

    return { average: Math.round(row.avg * 10) / 10, responses: row.count };
  }
}
