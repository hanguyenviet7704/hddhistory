import { Injectable, Logger } from '@nestjs/common';
import { InjectConnection, InjectModel } from '@nestjs/mongoose';
import { Connection, Model, PipelineStage } from 'mongoose';

import { AbstractRepository } from '@base/database/mongodb/abstract.repository';
import { ITranslation } from '@utils/interface/common.interface';

import { UserProgress } from '../../user-progress/schema/user-progress.schema';

export interface StudyDayCount {
  /** Local calendar day, `YYYY-MM-DD`. */
  date: string;
  keypoints: number;
}

export interface StudyDayItem {
  courseId: string;
  courseTitle: ITranslation;
  /** Row artwork: the course's image, else the lesson's, else the keypoint's. */
  image?: string;
  lessonId: string;
  lessonTitle: ITranslation;
  keypointId: string;
  keypointTitle: ITranslation;
  /** The keypoint's own estimated minutes; 0 when the content never set one. */
  minutes: number;
  passed: boolean;
  submittedAt: Date;
}

/**
 * Reads the study journal off `user_progress` — the keypoint submissions the
 * learner has actually made.
 *
 * `user_streaks` is NOT the source: it keeps a fixed 7-boolean window for the
 * CURRENT week only and resets on rollover, so it cannot answer "which days of
 * March did I study". `user_events` is not either — it is TTL-swept, so the
 * calendar would lose its own past.
 */
@Injectable()
export class StudyJournalRepository extends AbstractRepository<UserProgress> {
  protected readonly logger = new Logger(StudyJournalRepository.name);

  constructor(
    @InjectModel(UserProgress.name) model: Model<UserProgress>,
    @InjectConnection() connection: Connection,
  ) {
    super(model, connection);
  }

  /**
   * Keypoint submissions per LOCAL day inside one UTC window.
   *
   * The day boundary is the learner's, not the server's: a keypoint finished at
   * 00:30 in Hanoi belongs to that date, and grouping in UTC would file it under
   * the day before for every user east of Greenwich. `tzOffsetString` is handed
   * to `$dateToString` so the split happens in the database rather than being
   * re-derived from timestamps afterwards.
   */
  async countKeypointsPerDay(params: {
    userId: string;
    fromUtc: Date;
    toUtc: Date;
    tzOffsetString: string;
  }): Promise<StudyDayCount[]> {
    const rows = await this.model.aggregate<{ _id: string; count: number }>([
      { $match: { userId: params.userId } },
      { $unwind: '$lessonsResult' },
      { $unwind: '$lessonsResult.keypointsResult' },
      {
        $match: {
          'lessonsResult.keypointsResult.submittedAt': {
            $gte: params.fromUtc,
            $lt: params.toUtc,
          },
        },
      },
      {
        $group: {
          _id: {
            $dateToString: {
              format: '%Y-%m-%d',
              date: '$lessonsResult.keypointsResult.submittedAt',
              timezone: params.tzOffsetString,
            },
          },
          count: { $sum: 1 },
        },
      },
      { $sort: { _id: 1 } },
    ]);

    return rows.map(row => ({ date: row._id, keypoints: row.count }));
  }

  /**
   * The learner's very first keypoint submission, or null if they have none.
   *
   * Drives the calendar's "previous month" affordance: without it the arrow
   * would happily walk back through years of empty months, which reads as a
   * broken screen rather than as the end of the history.
   */
  async findFirstSubmissionAt(userId: string): Promise<Date | null> {
    const [row] = await this.model.aggregate<{ firstAt: Date }>([
      { $match: { userId } },
      { $unwind: '$lessonsResult' },
      { $unwind: '$lessonsResult.keypointsResult' },
      {
        $match: {
          'lessonsResult.keypointsResult.submittedAt': { $type: 'date' },
        },
      },
      {
        $group: {
          _id: null,
          firstAt: { $min: '$lessonsResult.keypointsResult.submittedAt' },
        },
      },
    ]);

    return row?.firstAt ?? null;
  }

  /**
   * What was studied inside one window, oldest first, with the course, lesson
   * and keypoint titles resolved in the same round trip.
   *
   * The ids are stored as strings while the referenced documents key on
   * ObjectId, so each lookup converts with `onError: null` — a legacy row
   * holding an unparseable id must drop its title, never fail the whole day.
   */
  async findItemsInWindow(params: {
    userId: string;
    fromUtc: Date;
    toUtc: Date;
  }): Promise<StudyDayItem[]> {
    const titleLookup = (
      from: string,
      localId: string,
      as: string,
    ): PipelineStage => ({
      $lookup: {
        from,
        let: {
          refId: {
            $convert: {
              input: localId,
              to: 'objectId',
              onError: null as null,
              onNull: null as null,
            },
          },
        },
        pipeline: [
          { $match: { $expr: { $eq: ['$_id', '$$refId'] } } },
          { $project: { title: 1, image: 1, estimateCompleTimeNumber: 1 } },
        ],
        as,
      },
    });

    return this.model.aggregate<StudyDayItem>([
      { $match: { userId: params.userId } },
      { $unwind: '$lessonsResult' },
      { $unwind: '$lessonsResult.keypointsResult' },
      {
        $match: {
          'lessonsResult.keypointsResult.submittedAt': {
            $gte: params.fromUtc,
            $lt: params.toUtc,
          },
        },
      },
      { $sort: { 'lessonsResult.keypointsResult.submittedAt': 1 } },
      titleLookup('keypoints', '$lessonsResult.keypointsResult.keypointId', 'keypointDoc'),
      titleLookup('lessons', '$lessonsResult.lessonId', 'lessonDoc'),
      titleLookup('courses', '$courseId', 'courseDoc'),
      {
        $project: {
          _id: 0,
          courseId: '$courseId',
          courseTitle: { $ifNull: [{ $first: '$courseDoc.title' }, {}] },
          // The COURSE cover is the row's picture: a day's list is read as
          // "which courses did I touch", and the keypoint's own illustration
          // would make two keypoints of one course look like two unrelated
          // things. Lesson then keypoint art only stand in when a course has
          // no cover, so a row is never left with an empty tile.
          image: {
            $ifNull: [
              { $first: '$courseDoc.image' },
              { $ifNull: [{ $first: '$lessonDoc.image' }, { $ifNull: [{ $first: '$keypointDoc.image' }, ''] }] },
            ],
          },
          lessonId: '$lessonsResult.lessonId',
          lessonTitle: { $ifNull: [{ $first: '$lessonDoc.title' }, {}] },
          keypointId: '$lessonsResult.keypointsResult.keypointId',
          keypointTitle: { $ifNull: [{ $first: '$keypointDoc.title' }, {}] },
          minutes: {
            $ifNull: [{ $first: '$keypointDoc.estimateCompleTimeNumber' }, 0],
          },
          passed: { $ifNull: ['$lessonsResult.keypointsResult.passed', false] },
          submittedAt: '$lessonsResult.keypointsResult.submittedAt',
        },
      },
    ]);
  }
}
