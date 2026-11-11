import { Injectable, Logger } from '@nestjs/common';
import { InjectConnection, InjectModel } from '@nestjs/mongoose';
import {
  Connection,
  FilterQuery,
  Model,
  ProjectionType,
  QueryOptions,
} from 'mongoose';
import { I18nContext, I18nService } from 'nestjs-i18n/dist';

import { AbstractRepository } from '@base/database/mongodb/abstract.repository';

import { GetUserProgressDto } from '../dto/get-list-user-progress.dto';
import { GradeResultType } from '../enum/user-progress.enum';
import { UserProgress } from '../schema/user-progress.schema';

export interface LatestStudiedKeypoint {
  courseId: string;
  lessonId: string;
  keypoint: {
    keypointId: string;
    passed?: boolean;
    exercisesResult?: { exerciseId: string }[];
    submittedAt?: Date;
  };
}

/**
 * `$bucket` default cho các lastTime rác — 1ms trước epoch, tức nhỏ hơn HẲN
 * boundary thấp nhất (`new Date(0)`), đúng luật Mongo đòi.
 */
const OUTLIER_BUCKET = new Date(-1);

@Injectable()
export class UserProgressRepository extends AbstractRepository<UserProgress> {
  protected readonly logger = new Logger(UserProgressRepository.name);
  constructor(
    @InjectModel(UserProgress.name) model: Model<UserProgress>,
    @InjectConnection() connection: Connection,
    private readonly i18n: I18nService,
  ) {
    super(model, connection);
  }
  get lang(): string {
    return I18nContext.current()?.lang ?? 'en';
  }

  async findOption(dto: any) {
    const { page, take, search, order, orderBy, userId, courseId } = dto;

    const where: FilterQuery<UserProgress> = {};

    if (userId) where.userId = userId;

    if (courseId) where.courseId = courseId;

    if (search) {
      where.$or = [
        { [`title.${this.lang}`]: { $regex: search, $options: 'i' } },
        { [`description.${this.lang}`]: { $regex: search, $options: 'i' } },
      ];
    }

    return this.paginateQuery<UserProgress>({
      where,
      page,
      take,
      orderBy,
      order,
    });
  }

  async findOneOption(
    where: FilterQuery<UserProgress>,
    select?: ProjectionType<UserProgress>,
    option?: QueryOptions,
  ) {
    return this.model.findOne(where, select, option);
  }

  async getKeypointsPassed(userId: string) {
    const result = await this.model.find({ userId }, { keypointsCompleted: 1 });

    return result;
  }

  /**
   * Distinct keypoint ids this user has PASSED, across every course. Reads only
   * the nested id/passed pairs — progress docs carry full per-exercise answer
   * payloads that nothing here needs.
   */
  async findPassedKeypointIds(userId: string): Promise<string[]> {
    const rows = await this.model.find(
      { userId },
      {
        'lessonsResult.keypointsResult.keypointId': 1,
        'lessonsResult.keypointsResult.passed': 1,
      },
    );

    const ids = new Set<string>();
    for (const row of rows as any[]) {
      for (const lesson of row.lessonsResult ?? []) {
        for (const keypoint of lesson.keypointsResult ?? []) {
          if (keypoint?.passed && keypoint.keypointId) {
            ids.add(keypoint.keypointId.toString());
          }
        }
      }
    }
    return Array.from(ids);
  }

  /**
   * Every keypoint this user has PASSED, across every course, with where it
   * sits and when it was last submitted. Seeds the spaced-review schedule:
   * a keypoint enters review one interval after the reader learned it.
   *
   * A keypoint passed in two courses keeps the most recent submission.
   */
  async findPassedKeypoints(userId: string): Promise<
    {
      keypointId: string;
      lessonId: string;
      courseId: string;
      submittedAt: Date | null;
    }[]
  > {
    const rows = await this.model
      .find(
        { userId },
        {
          courseId: 1,
          'lessonsResult.lessonId': 1,
          'lessonsResult.keypointsResult.keypointId': 1,
          'lessonsResult.keypointsResult.passed': 1,
          'lessonsResult.keypointsResult.submittedAt': 1,
        },
      )
      .lean();

    const byKeypoint = new Map<
      string,
      {
        keypointId: string;
        lessonId: string;
        courseId: string;
        submittedAt: Date | null;
      }
    >();
    for (const row of rows as any[]) {
      for (const lesson of row.lessonsResult ?? []) {
        for (const keypoint of lesson.keypointsResult ?? []) {
          if (!keypoint?.passed || !keypoint.keypointId) continue;
          const keypointId = keypoint.keypointId.toString();
          const submittedAt = keypoint.submittedAt
            ? new Date(keypoint.submittedAt)
            : null;
          const previous = byKeypoint.get(keypointId);
          if (
            previous &&
            (previous.submittedAt?.getTime() ?? 0) >=
              (submittedAt?.getTime() ?? 0)
          ) {
            continue;
          }
          byKeypoint.set(keypointId, {
            keypointId,
            lessonId: lesson.lessonId?.toString() ?? '',
            courseId: row.courseId?.toString() ?? '',
            submittedAt,
          });
        }
      }
    }
    return Array.from(byKeypoint.values());
  }

  /**
   * Progress rows for a specific set of courses, carrying only what
   * `countPassedItems` needs. Backs the saved-courses list, which has to know
   * each saved course's completion before it can bucket it into
   * up-next / in-progress / finished.
   */
  async findProgressByCourseIds(
    userId: string,
    courseIds: string[],
  ): Promise<Pick<UserProgress, 'courseId' | 'lessonsResult'>[]> {
    if (!courseIds.length) return [];

    return this.model
      .find(
        { userId, courseId: { $in: courseIds } },
        {
          courseId: 1,
          'lessonsResult.lessonType': 1,
          'lessonsResult.passed': 1,
          'lessonsResult.keypointsResult.passed': 1,
        },
      )
      .lean() as unknown as Promise<
      Pick<UserProgress, 'courseId' | 'lessonsResult'>[]
    >;
  }

  /**
   * Every course the reader has ANY progress row on — started or finished.
   *
   * The Coach's course card excludes these: a course somebody is already in,
   * or has finished, is not a direction to point them in.
   */
  /**
   * Khi người này BẮT ĐẦU khoá đó, hoặc null nếu chưa từng. Dùng để quyết ai
   * vào đợt A/B nội dung: người đã học từ trước khi đợt mở thì giữ nguyên tag
   * đang phát hành, vì đổi nội dung giữa đường vừa hỏng trải nghiệm vừa trộn
   * hai bản vào cùng một con số.
   *
   * Chỉ lấy `createdAt` và ăn index `{ userId, courseId }` — nó nằm trên đường
   * serve của khoá đang trong đợt.
   */
  async findCourseStartedAt(
    userId: string,
    courseId: string,
  ): Promise<Date | null> {
    const row = await this.model
      .findOne({ userId, courseId }, { createdAt: 1, _id: 0 })
      .lean<{ createdAt?: Date }>();

    return row?.createdAt ?? null;
  }

  async findCourseIdsForUser(userId: string): Promise<string[]> {
    const ids = await this.model.distinct('courseId', { userId });

    return ids.map((id) => String(id)).filter(Boolean);
  }

  async getUserProgress(dto: GetUserProgressDto) {
    const { userId, courseId, lessonId, keypointId, exerciseId, grade } = dto;

    const match: any = { courseId };
    let aggregate: any[] = [{ $match: match }];
    if (userId) match.userId = userId;

    switch (grade) {
      case GradeResultType.COURSE:
        break;
      case GradeResultType.LESSON:
        aggregate = [
          { $match: match },
          { $unwind: '$lessonsResult' },
          { $match: { 'lessonsResult.lessonId': lessonId } },
          { $project: { _id: 0, userId: 1, lesson: '$lessonsResult' } },
        ];
        break;
      case GradeResultType.KEYPOINT:
        aggregate = [
          { $match: match },
          { $unwind: '$lessonsResult' },
          { $match: { 'lessonsResult.lessonId': lessonId } },
          { $unwind: '$lessonsResult.keypointsResult' },
          {
            $match: { 'lessonsResult.keypointsResult.keypointId': keypointId },
          },
          {
            $project: {
              _id: 0,
              userId: 1,
              keypoint: '$lessonsResult.keypointsResult',
            },
          },
        ];
        break;
      case GradeResultType.EXERCISE:
        aggregate = [
          { $match: match },
          { $unwind: '$lessonsResult' },
          { $match: { 'lessonsResult.lessonId': lessonId } },
          { $unwind: '$lessonsResult.keypointsResult' },
          {
            $match: { 'lessonsResult.keypointsResult.keypointId': keypointId },
          },
          { $unwind: '$lessonsResult.keypointsResult.exercisesResult' },
          {
            $match: {
              'lessonsResult.keypointsResult.exercisesResult.exerciseId':
                exerciseId,
            },
          },
          {
            $project: {
              _id: 0,
              userId: 1,
              exercise: '$lessonsResult.keypointsResult.exercisesResult',
            },
          },
        ];
        break;
      default:
        break;
    }

    const result = await this.model.aggregate(aggregate);

    return result;
  }

  async findLatestStudiedKeypoint(
    userId: string,
    courseId?: string,
  ): Promise<LatestStudiedKeypoint | null> {
    const match: any = { userId };
    if (courseId) {
      match.courseId = courseId;
    }
    const [latest] = await this.model.aggregate<LatestStudiedKeypoint>([
      { $match: match },
      { $unwind: '$lessonsResult' },
      { $unwind: '$lessonsResult.keypointsResult' },
      { $sort: { 'lessonsResult.keypointsResult.submittedAt': -1 } },
      { $limit: 1 },
      {
        $project: {
          _id: 0,
          courseId: 1,
          lessonId: '$lessonsResult.lessonId',
          keypoint: '$lessonsResult.keypointsResult',
        },
      },
    ]);

    return latest ?? null;
  }

  /**
   * Where the user put a lesson down, newest course activity first — the source
   * for the 14:00 "you left something unfinished" notification.
   *
   * Reads `stopAt`, not the completed-keypoint history: `stopAt` is the only field
   * that records an ABANDONED position, which is exactly the case the reminder is
   * about. Lessons already listed as passed are filtered out by the caller, which
   * owns the "unfinished" definition.
   *
   * Returns up to [limit] courses rather than only the newest one. With a single
   * row, a reader who finished the lesson they last stopped at got no nudge at
   * all — even with another course still abandoned — because the caller's
   * already-passed filter had nothing left to fall back on.
   */
  /**
   * Where this course's readers are stuck, counted per stop point — the
   * admin drop-off panel's one query.
   *
   * `cutoff` separates "stopped" from "merely mid-course": a reader whose
   * `lastTime` is newer than it is still learning, and counting them as
   * drop-offs would paint every popular course as a graveyard. Null means no
   * filter (count everyone in progress).
   *
   * Grouped by the (lessonId, keypointId) PAIR, not keypointId alone:
   * `stopAt.keypointId` is optional (a video lesson has no keypoint), and
   * those readers still stopped somewhere worth counting — they group under
   * their lesson with a null keypoint.
   */
  async aggregateDropOffByCourse(
    courseId: string,
    cutoff: Date | null,
  ): Promise<{
    totalInProgress: number;
    totalStuck: number;
    rows: { lessonId: string; keypointId: string | null; count: number }[];
  }> {
    const stuckMatch: Record<string, unknown> = {
      courseId,
      'stopAt.lessonId': { $exists: true, $ne: null },
    };
    if (cutoff) stuckMatch.lastTime = { $lte: cutoff };

    const [totalInProgress, grouped] = await Promise.all([
      this.model.countDocuments({ courseId }),
      this.model.aggregate<{
        _id: { lessonId: string; keypointId: string | null };
        count: number;
      }>([
        { $match: stuckMatch },
        {
          $group: {
            _id: {
              lessonId: '$stopAt.lessonId',
              keypointId: { $ifNull: ['$stopAt.keypointId', null] },
            },
            count: { $sum: 1 },
          },
        },
        { $sort: { count: -1 } },
      ]),
    ]);

    const rows = grouped.map(row => ({
      lessonId: row._id.lessonId,
      keypointId: row._id.keypointId,
      count: row.count,
    }));

    return {
      totalInProgress,
      totalStuck: rows.reduce((sum, row) => sum + row.count, 0),
      rows,
    };
  }

  /**
   * Every course's in-progress vs stuck counts in one pass — the drop-off
   * page's course list, which doubles as a "course nào rơi nhiều nhất"
   * ranking. Same stuck definition as [aggregateDropOffByCourse], and the two
   * must not drift: the list's number is the headline the detail explains.
   */
  async aggregateDropOffOverview(cutoff: Date | null): Promise<
    { courseId: string; totalInProgress: number; totalStuck: number }[]
  > {
    const stuckConditions: unknown[] = [
      // $ifNull -> false turns "field absent" into false; any lessonId string
      // is truthy. Cheaper than $type checks and reads as what it means.
      { $ifNull: ['$stopAt.lessonId', false] },
    ];
    if (cutoff) stuckConditions.push({ $lte: ['$lastTime', cutoff] });

    const rows = await this.model.aggregate<{
      _id: string;
      totalInProgress: number;
      totalStuck: number;
    }>([
      {
        $group: {
          _id: '$courseId',
          totalInProgress: { $sum: 1 },
          totalStuck: {
            $sum: { $cond: [{ $and: stuckConditions }, 1, 0] },
          },
        },
      },
      { $sort: { totalStuck: -1, totalInProgress: -1 } },
    ]);

    return rows.map(row => ({
      courseId: row._id,
      totalInProgress: row.totalInProgress,
      totalStuck: row.totalStuck,
    }));
  }

  /**
   * How long this course's stuck readers have been away, bucketed — the
   * "kẹt bao lâu rồi" chart. Deliberately NOT filtered by the page's
   * staleDays: this chart is the distribution that filter cuts through, and
   * filtering it by itself would make every bar left of the cutoff vanish.
   */
  async aggregateStalenessBuckets(
    courseId: string,
  ): Promise<{ bucket: string; count: number }[]> {
    const now = Date.now();
    const day = 24 * 60 * 60 * 1000;
    // Ascending lastTime boundaries: older = away longer. The far future top
    // bound keeps a lastTime written between now and the query out of $bucket's
    // default(error) path.
    const boundaries = [
      new Date(0),
      new Date(now - 90 * day),
      new Date(now - 30 * day),
      new Date(now - 14 * day),
      new Date(now - 7 * day),
      new Date(now + day),
    ];
    const labels = ['90+ ngày', '30–90 ngày', '14–30 ngày', '7–14 ngày', '< 7 ngày'];

    const rows = await this.model.aggregate<{ _id: Date; count: number }>([
      {
        $match: {
          courseId,
          'stopAt.lessonId': { $exists: true, $ne: null },
          lastTime: { $ne: null },
        },
      },
      {
        $bucket: {
          groupBy: '$lastTime',
          boundaries,
          // STRICTLY below the lowest boundary — Mongo rejects a default that
          // EQUALS a boundary ("must be less than the lowest boundary or
          // greater than or equal to the highest"), and that rejection is a
          // runtime 500, invisible to every compile-time gate. This bucket
          // catches only garbage dates (before epoch, or clock-skew writes
          // beyond now+1d); they are folded into "90+ ngày" below rather than
          // dropped — a reader with an unparseable lastTime is still a reader
          // this chart exists to count, and "away forever" is the least wrong
          // shelf for them.
          default: OUTLIER_BUCKET,
          output: { count: { $sum: 1 } },
        },
      },
    ]);

    const countByBoundary = new Map(
      rows.map(row => [new Date(row._id).getTime(), row.count]),
    );
    const outliers = countByBoundary.get(OUTLIER_BUCKET.getTime()) ?? 0;

    // Every bucket present even at zero: a distribution chart with missing
    // bars reads as missing data, not as "nobody there".
    return labels.map((bucket, index) => ({
      bucket,
      count:
        (countByBoundary.get(boundaries[index].getTime()) ?? 0) +
        (index === 0 ? outliers : 0),
    }));
  }

  async findRecentStopAts(
    userId: string,
    limit = 20,
  ): Promise<
    {
      courseId: string;
      lessonId: string;
      keypointId?: string;
      passedLessonIds: string[];
      lastTime?: Date;
    }[]
  > {
    const rows = await this.model
      .find(
        { userId, 'stopAt.lessonId': { $exists: true, $ne: '' } },
        { courseId: 1, stopAt: 1, lastTime: 1, 'lessonsResult.lessonId': 1, 'lessonsResult.passed': 1 },
      )
      .sort({ lastTime: -1 })
      .limit(limit)
      .lean();

    return rows
      .filter(row => !!row?.stopAt?.lessonId)
      .map(row => ({
        courseId: row.courseId,
        lessonId: row.stopAt.lessonId,
        keypointId: row.stopAt.keypointId,
        passedLessonIds: (row.lessonsResult ?? [])
          .filter(lesson => lesson.passed)
          .map(lesson => lesson.lessonId),
        lastTime: row.lastTime,
      }));
  }

  removeManyByUserId(userId: string) {
    return this.model.deleteMany({ userId });
  }

  /**
   * Most recent activity timestamp across ALL of the user's courses.
   * Used to decide global inactivity for the lesson warm-up feature.
   */
  async findGlobalLastActivity(userId: string): Promise<Date | null> {
    const [latest] = await this.model.aggregate<{ lastActivity: Date }>([
      { $match: { userId } },
      {
        $project: {
          lastActivity: { $ifNull: ['$lastTime', '$updatedAt'] },
        },
      },
      { $sort: { lastActivity: -1 } },
      { $limit: 1 },
    ]);

    return latest?.lastActivity ?? null;
  }

  /**
   * All lesson ids the user has submitted results for within a single
   * course (unordered — course position is resolved by the caller against
   * the Lesson collection). Used by the lesson warm-up feature to find the
   * furthest lesson the user has reached in the course.
   */
  async findStudiedLessonIdsInCourse(
    userId: string,
    courseId: string,
  ): Promise<string[]> {
    const progress = await this.model
      .findOne(
        { userId, courseId },
        { 'lessonsResult.lessonId': 1 },
      )
      .lean();

    return (progress?.lessonsResult ?? [])
      .map(result => result.lessonId)
      .filter(Boolean);
  }
}
