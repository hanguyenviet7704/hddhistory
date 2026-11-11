import { Injectable } from '@nestjs/common';
import { InjectModel } from '@nestjs/mongoose';
import { FilterQuery, Model } from 'mongoose';

import { buildEventMatch, percentileOf } from './dashboard-match.helper';
import {
  COACH_BREAKDOWN_LIMIT,
  COACH_MEDIAN,
  COACH_MIC_DONE,
  COACH_MIC_START,
  COACH_P90,
  COACH_QUIZ_RUN,
  COACH_TURN_SEND,
  PARAM_CHIP_LIST,
  PARAM_GRANTED,
  PARAM_HAS_TEXT,
  PARAM_QUIZ_COUNT,
  PARAM_QUIZ_PASSED,
} from '../constant/coach-dashboard.constant';
import { ICoachNumericStats } from '../interface/coach-dashboard.interface';
import { IDashboardFilter } from '../interface/dashboard.interface';
import { UserEvent } from '../schema/user-event.schema';


/** One row of a `params.<field>` breakdown, straight out of Mongo. */
export interface ICoachBreakdownCount {
  /** The raw param value, stringified. Empty when the event carried none. */
  id: string;
  events: number;
  users: number;
}

/** How one dimension's sessions ended, before the service turns it into a rate. */
export interface ICoachOutcomeCount {
  id: string;
  completed: number;
  abandoned: number;
}

export interface ICoachQuizTotals {
  runs: number;
  questions: number;
  passed: number;
}

export interface ICoachMicTotals {
  starts: number;
  granted: number;
  done: number;
  withText: number;
}

/**
 * The aggregations behind the Coach statistics page.
 *
 * Separate from [AnalyticsDashboardRepository] for one reason: every query here
 * reaches into `params`, the free-form bag the app fills, rather than into the
 * event's own columns. That makes them a different kind of pipeline — they hang
 * on string paths that only the Coach's tracking uses — and mixing them into a
 * file that is already 1300 lines would have buried both.
 *
 * Plain counts (`coach_x` happened N times to M people) are NOT here: that is
 * `eventTotals` on the other repository, and duplicating it would be two
 * definitions of the same number.
 *
 * Nothing here interprets. Rates, labels and comparison periods are the
 * service's job; this layer only talks to Mongo.
 */
@Injectable()
export class CoachDashboardRepository {
  constructor(
    @InjectModel(UserEvent.name)
    private readonly eventModel: Model<UserEvent>,
  ) {}

  private match(
    filter: IDashboardFilter,
    name: string | string[],
    extra: FilterQuery<UserEvent> = {},
  ): FilterQuery<UserEvent> {
    return {
      ...buildEventMatch(filter),
      name: Array.isArray(name) ? { $in: name } : name,
      ...extra,
    };
  }

  /**
   * One event grouped by one `params` field.
   *
   * The double `$group` is what separates "lượt" from "người": the inner one
   * collapses each (value, user) pair so the outer can count users without a
   * second pass. Values arrive as whatever the app put there — `true`, `null`,
   * a string — and leave as a string, because the panel renders them as labels
   * and `null` and `'null'` must not become two different rows.
   */
  async paramBreakdown(
    filter: IDashboardFilter,
    event: string,
    paramPath: string,
    options: { match?: FilterQuery<UserEvent>; limit?: number } = {},
  ): Promise<ICoachBreakdownCount[]> {
    const rows = await this.eventModel.aggregate([
      { $match: this.match(filter, event, options.match) },
      {
        $group: {
          _id: { value: `$${paramPath}`, userId: '$userId' },
          count: { $sum: 1 },
        },
      },
      {
        $group: {
          _id: '$_id.value',
          events: { $sum: '$count' },
          users: { $sum: 1 },
        },
      },
      { $sort: { events: -1 } },
      { $limit: options.limit ?? COACH_BREAKDOWN_LIMIT },
    ]);

    return rows.map((row) => ({
      id: row._id === null || row._id === undefined ? '' : String(row._id),
      events: row.events,
      users: row.users,
    }));
  }

  /**
   * A numeric param's distribution, split by a second param.
   *
   * Backs "how long did a finished session run, and how long did an abandoned
   * one" in a single pass — asking that as two queries would scan the same
   * range twice for two halves of one answer.
   *
   * `$sort` before `$group` is what makes the percentile indexes valid: `$push`
   * keeps input order, so the array it builds is already sorted. Same idiom as
   * the session-duration pipeline next door, and it works on every Mongo
   * version — `$percentile` would need 7.
   */
  async numericStatsByOutcome(
    filter: IDashboardFilter,
    event: string,
    valuePath: string,
    outcomePath: string,
  ): Promise<Record<string, ICoachNumericStats>> {
    const rows = await this.eventModel.aggregate([
      {
        $match: this.match(filter, event, {
          [valuePath]: { $type: 'number' },
        } as FilterQuery<UserEvent>),
      },
      { $sort: { [valuePath]: 1 } },
      {
        $group: {
          _id: `$${outcomePath}`,
          values: { $push: `$${valuePath}` },
          count: { $sum: 1 },
          total: { $sum: `$${valuePath}` },
        },
      },
      {
        $project: {
          count: 1,
          mean: { $divide: ['$total', '$count'] },
          median: percentileOf('values', 'count', COACH_MEDIAN),
          p90: percentileOf('values', 'count', COACH_P90),
        },
      },
    ]);

    return rows.reduce(
      (acc, row) => ({
        ...acc,
        [row._id === null || row._id === undefined ? '' : String(row._id)]: {
          count: row.count,
          mean: row.mean ?? null,
          median: row.median ?? null,
          p90: row.p90 ?? null,
        },
      }),
      {} as Record<string, ICoachNumericStats>,
    );
  }

  /**
   * A boolean outcome crossed with a dimension — "which door leads to finishing".
   *
   * Counted in sessions rather than people on purpose: the question is about
   * journeys, and one reader who finishes on Monday and gives up on Tuesday is
   * both answers, not one.
   */
  async outcomeByParam(
    filter: IDashboardFilter,
    event: string,
    outcomePath: string,
    dimensionPath: string,
  ): Promise<ICoachOutcomeCount[]> {
    const rows = await this.eventModel.aggregate([
      { $match: this.match(filter, event) },
      {
        $group: {
          _id: `$${dimensionPath}`,
          completed: {
            $sum: { $cond: [{ $eq: [`$${outcomePath}`, true] }, 1, 0] },
          },
          abandoned: {
            $sum: { $cond: [{ $eq: [`$${outcomePath}`, false] }, 1, 0] },
          },
        },
      },
      { $sort: { completed: -1, abandoned: -1 } },
    ]);

    return rows.map((row) => ({
      id: row._id === null || row._id === undefined ? '' : String(row._id),
      completed: row.completed,
      abandoned: row.abandoned,
    }));
  }

  /**
   * The reasons behind a 👎, one row per chip.
   *
   * The app sends them as one comma-joined string of five closed ids — never
   * text somebody typed — so unwinding it here is safe and is the only way to
   * count a reason that was picked alongside another.
   */
  async chipBreakdown(
    filter: IDashboardFilter,
  ): Promise<ICoachBreakdownCount[]> {
    const rows = await this.eventModel.aggregate([
      {
        $match: this.match(filter, COACH_TURN_SEND, {
          [PARAM_CHIP_LIST]: { $type: 'string', $ne: '' },
        } as FilterQuery<UserEvent>),
      },
      {
        $project: {
          userId: 1,
          chip: { $split: [`$${PARAM_CHIP_LIST}`, ','] },
        },
      },
      { $unwind: '$chip' },
      {
        $group: {
          _id: { chip: '$chip', userId: '$userId' },
          count: { $sum: 1 },
        },
      },
      {
        $group: {
          _id: '$_id.chip',
          events: { $sum: '$count' },
          users: { $sum: 1 },
        },
      },
      { $sort: { events: -1 } },
      { $limit: COACH_BREAKDOWN_LIMIT },
    ]);

    return rows.map((row) => ({
      id: String(row._id ?? '').trim(),
      events: row.events,
      users: row.users,
    }));
  }

  /**
   * Quiz volume and how much of it was passed.
   *
   * Two events in one pass because they answer one question: `coach_quiz_run`
   * says a quiz started, and the `kind=quizAnswer` turn carries how many
   * questions it held and how many were right.
   */
  async quizTotals(filter: IDashboardFilter): Promise<ICoachQuizTotals> {
    const [row] = await this.eventModel.aggregate([
      { $match: this.match(filter, [COACH_QUIZ_RUN, COACH_TURN_SEND]) },
      {
        $group: {
          _id: null,
          runs: {
            $sum: { $cond: [{ $eq: ['$name', COACH_QUIZ_RUN] }, 1, 0] },
          },
          questions: { $sum: { $ifNull: [`$${PARAM_QUIZ_COUNT}`, 0] } },
          passed: { $sum: { $ifNull: [`$${PARAM_QUIZ_PASSED}`, 0] } },
        },
      },
    ]);

    return {
      runs: row?.runs ?? 0,
      questions: row?.questions ?? 0,
      passed: row?.passed ?? 0,
    };
  }

  /**
   * The microphone, start to finish.
   *
   * `granted` is the OS permission answer and `withText` is whether dictation
   * produced anything — two different ways the feature fails, and the pair is
   * what tells them apart.
   */
  async micTotals(filter: IDashboardFilter): Promise<ICoachMicTotals> {
    const isStart = { $eq: ['$name', COACH_MIC_START] };
    const isDone = { $eq: ['$name', COACH_MIC_DONE] };

    const [row] = await this.eventModel.aggregate([
      { $match: this.match(filter, [COACH_MIC_START, COACH_MIC_DONE]) },
      {
        $group: {
          _id: null,
          starts: { $sum: { $cond: [isStart, 1, 0] } },
          granted: {
            $sum: {
              $cond: [
                { $and: [isStart, { $eq: [`$${PARAM_GRANTED}`, true] }] },
                1,
                0,
              ],
            },
          },
          done: { $sum: { $cond: [isDone, 1, 0] } },
          withText: {
            $sum: {
              $cond: [
                { $and: [isDone, { $eq: [`$${PARAM_HAS_TEXT}`, true] }] },
                1,
                0,
              ],
            },
          },
        },
      },
    ]);

    return {
      starts: row?.starts ?? 0,
      granted: row?.granted ?? 0,
      done: row?.done ?? 0,
      withText: row?.withText ?? 0,
    };
  }
}
