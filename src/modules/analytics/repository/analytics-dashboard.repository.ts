import { Injectable, Logger } from '@nestjs/common';
import { InjectModel } from '@nestjs/mongoose';
import { FilterQuery, Model, PipelineStage, Types } from 'mongoose';

import { User } from 'src/modules/user/src/modules/auth/schema/user.schema';

import {
  buildDimensionOnlyMatch,
  buildEventMatch,
  dateStringField,
  percentileOf,
} from './dashboard-match.helper';
import {
  BOUNCE_SESSION_MS,
  DURATION_PERCENTILES,
  ENGAGED_SESSION_MIN_MS,
  ENGAGED_SESSION_MIN_SCREENS,
  LEARNING_EVENT_PATTERN,
  LONG_SESSION_MS,
  ONBOARDING_COMPLETED_STEP,
  ONBOARDING_EVENT_PREFIX,
  ONBOARDING_STEP_SUFFIX,
  SESSION_DEPTH_BUCKETS,
  TOP_LIST_LIMIT,
} from '../constant/dashboard.constant';
import { UserEventKind } from '../enum/analytics.enum';
import {
  IDashboardFilter,
  IDepthBucket,
  IHeatmapCell,
  IHourPoint,
  INameValue,
  ITopContentRow,
  IVersionDuration,
  IWeekdayDuration,
} from '../interface/dashboard.interface';
import { UserEvent } from '../schema/user-event.schema';

const DAY_MS = 24 * 60 * 60 * 1000;

/**
 * Every cross-user aggregation behind the admin product dashboard.
 *
 * Deliberately separate from [UserEventRepository]: that one answers "what did
 * *this* user do" and every one of its queries starts with `userId`. These
 * start with a date range across all users, which is a different index and a
 * different set of pipelines — mixing them in one class made both harder to
 * read.
 *
 * Nothing here interprets its numbers. Rates, deltas and comparison periods are
 * the service's job; this layer only talks to Mongo.
 */
@Injectable()
export class AnalyticsDashboardRepository {
  private readonly logger = new Logger(AnalyticsDashboardRepository.name);

  constructor(
    @InjectModel(UserEvent.name)
    private readonly eventModel: Model<UserEvent>,
    @InjectModel(User.name)
    private readonly userModel: Model<User>,
  ) {}

  /**
   * Range + dimension filters, the shape every event pipeline starts with.
   *
   * The three below are thin wrappers over `dashboard-match.helper` so that
   * this class and [CoachDashboardRepository] cannot disagree about what a
   * filter means. Kept as methods rather than replacing ~30 `this.` call sites.
   */
  private buildMatch(filter: IDashboardFilter): FilterQuery<UserEvent> {
    return buildEventMatch(filter);
  }

  private buildDimensionMatch(
    filter: IDashboardFilter,
  ): Record<string, unknown> {
    return buildDimensionOnlyMatch(filter);
  }

  private dateField(field: string, timezone: string) {
    return dateStringField(field, timezone);
  }

  // ---------------------------------------------------------------- users

  async countActiveUsers(filter: IDashboardFilter): Promise<number> {
    const [row] = await this.eventModel.aggregate([
      { $match: this.buildMatch(filter) },
      { $group: { _id: '$userId' } },
      { $count: 'total' },
    ]);

    return row?.total ?? 0;
  }

  /**
   * Distinct users inside an arbitrary window, keeping the current dimension
   * filters. Backs the rolling DAU / WAU / MAU cards, whose windows are not the
   * report's own range.
   */
  async countActiveUsersInWindow(
    filter: IDashboardFilter,
    from: Date,
    to: Date,
  ): Promise<number> {
    return this.countActiveUsers({ ...filter, from, to });
  }

  /** DAU split by platform — the two lines of the daily-active chart. */
  async dailyActiveUsersByPlatform(
    filter: IDashboardFilter,
  ): Promise<{ date: string; platform: string; users: number }[]> {
    const rows = await this.eventModel.aggregate([
      { $match: this.buildMatch(filter) },
      {
        $group: {
          _id: {
            date: this.dateField('clientTs', filter.timezone),
            platform: '$platform',
            userId: '$userId',
          },
        },
      },
      {
        $group: {
          _id: { date: '$_id.date', platform: '$_id.platform' },
          users: { $sum: 1 },
        },
      },
      { $sort: { '_id.date': 1 } },
    ]);

    return rows
      .filter((row) => row._id.platform)
      .map((row) => ({
        date: row._id.date,
        platform: String(row._id.platform),
        users: row.users,
      }));
  }

  /**
   * Who the people who signed up in this range are, from their own profile.
   *
   * Read off the `users` documents rather than the event stream: age is
   * answered once during onboarding and never repeated as an event parameter.
   * Country is reported the same way, but nothing in the API writes that field
   * today — the caller is expected to tell the panel when it came back empty
   * rather than draw an empty chart.
   */
  async demographics(
    from: Date,
    to: Date,
    countryLimit: number,
  ): Promise<{ byCountry: INameValue[]; byAge: INameValue[] }> {
    const [result] = await this.userModel.aggregate([
      { $match: { createdAt: { $gte: from, $lte: to } } },
      {
        $facet: {
          byCountry: [
            { $match: { country: { $type: 'string', $ne: '' } } },
            { $group: { _id: '$country', users: { $sum: 1 } } },
            { $sort: { users: -1 } },
            { $limit: countryLimit },
          ],
          byAge: [
            { $match: { age: { $type: 'string', $ne: '' } } },
            { $group: { _id: '$age', users: { $sum: 1 } } },
            { $sort: { users: -1 } },
          ],
        },
      },
    ]);

    const toPairs = (rows: any[]): INameValue[] =>
      (rows ?? []).map((row) => ({ name: String(row._id), value: row.users }));

    return {
      byCountry: toPairs(result?.byCountry),
      byAge: toPairs(result?.byAge),
    };
  }

  async dailyActiveUsers(
    filter: IDashboardFilter,
  ): Promise<{ date: string; users: number }[]> {
    const rows = await this.eventModel.aggregate([
      { $match: this.buildMatch(filter) },
      {
        $group: {
          _id: {
            date: this.dateField('clientTs', filter.timezone),
            userId: '$userId',
          },
        },
      },
      { $group: { _id: '$_id.date', users: { $sum: 1 } } },
      { $sort: { _id: 1 } },
    ]);

    return rows.map((row) => ({ date: row._id, users: row.users }));
  }

  /**
   * Accounts created in the range.
   *
   * Counted from `users.createdAt` rather than "first event seen", because
   * `user_events` expires after 90 days: a user who came back after a long
   * absence would look brand new. There is no `appEnv` on a user document —
   * environments are separate databases — so this number ignores that filter.
   */
  async countNewUsers(from: Date, to: Date): Promise<number> {
    return this.userModel.countDocuments({
      createdAt: { $gte: from, $lte: to },
    });
  }

  async dailyNewUsers(
    from: Date,
    to: Date,
    timezone: string,
  ): Promise<{ date: string; users: number }[]> {
    const rows = await this.userModel.aggregate([
      { $match: { createdAt: { $gte: from, $lte: to } } },
      {
        $group: {
          _id: this.dateField('createdAt', timezone),
          users: { $sum: 1 },
        },
      },
      { $sort: { _id: 1 } },
    ]);

    return rows.map((row) => ({ date: row._id, users: row.users }));
  }

  /** Distinct users per platform / app version, for the breakdown lists. */
  async usersByDimension(
    filter: IDashboardFilter,
    field: 'platform' | 'appVersion',
  ): Promise<INameValue[]> {
    const rows = await this.eventModel.aggregate([
      { $match: this.buildMatch(filter) },
      { $group: { _id: { value: `$${field}`, userId: '$userId' } } },
      { $group: { _id: '$_id.value', users: { $sum: 1 } } },
      { $sort: { users: -1 } },
    ]);

    return rows
      .filter((row) => row._id)
      .map((row) => ({ name: String(row._id), value: row.users }));
  }

  /**
   * Cohort retention: of the users who signed up on day D, how many fired an
   * event on day D+offset.
   *
   * Two details that decide whether the number is honest:
   *
   * - The window is the *calendar day* D+offset in the report's timezone, not
   *   "offset × 24h after the exact signup instant". That is what GA4 reports
   *   and what anyone reading "quay lại sau ngày 1" expects.
   * - A cohort only counts once its window has fully passed (`mature`).
   *   Yesterday's signups cannot have a D7 number yet, and averaging them in as
   *   zeros is how a healthy D7 gets reported as a collapse.
   */
  async retentionCohorts(
    filter: IDashboardFilter,
    offsets: number[],
    now: Date,
  ): Promise<{
    overall: { offset: number; cohortUsers: number; retained: number }[];
    byAppVersion: {
      appVersion: string;
      offset: number;
      cohortUsers: number;
      retained: number;
    }[];
    byPlatform: {
      platform: string;
      offset: number;
      cohortUsers: number;
      retained: number;
    }[];
  }> {
    const dimensionMatch = this.buildDimensionMatch(filter);

    const lookups: PipelineStage[] = offsets.flatMap((offset) => [
      {
        $lookup: {
          from: 'user_events',
          let: {
            uid: '$_id',
            windowStart: {
              $add: ['$cohortStart', offset * DAY_MS],
            },
            windowEnd: {
              $add: ['$cohortStart', (offset + 1) * DAY_MS],
            },
          },
          pipeline: [
            {
              $match: {
                ...dimensionMatch,
                $expr: {
                  $and: [
                    { $eq: ['$userId', '$$uid'] },
                    { $gte: ['$clientTs', '$$windowStart'] },
                    { $lt: ['$clientTs', '$$windowEnd'] },
                  ],
                },
              },
            },
            { $limit: 1 },
            { $project: { _id: 1 } },
          ],
          as: `retained_${offset}`,
        },
      } as PipelineStage,
      {
        $addFields: {
          [`mature_${offset}`]: {
            $lte: [{ $add: ['$cohortStart', (offset + 1) * DAY_MS] }, now],
          },
          [`retained_${offset}`]: { $gt: [{ $size: `$retained_${offset}` }, 0] },
        },
      } as PipelineStage,
    ]);

    const cohortAccumulators = offsets.reduce(
      (acc, offset) => ({
        ...acc,
        [`cohort_${offset}`]: {
          $sum: { $cond: [`$mature_${offset}`, 1, 0] },
        },
        [`retained_${offset}`]: {
          $sum: {
            $cond: [
              { $and: [`$mature_${offset}`, `$retained_${offset}`] },
              1,
              0,
            ],
          },
        },
      }),
      {} as Record<string, unknown>,
    );

    const [result] = await this.userModel.aggregate([
      { $match: { createdAt: { $gte: filter.from, $lte: filter.to } } },
      {
        $project: {
          _id: 1,
          cohortStart: {
            $dateFromString: {
              dateString: this.dateField('createdAt', filter.timezone),
              timezone: filter.timezone,
            },
          },
        },
      },
      // The build the user was first seen on. Retention "theo bản app" is the
      // whole point of shipping a release, so it is worth one extra indexed
      // lookup per cohort member.
      {
        $lookup: {
          from: 'user_events',
          let: { uid: '$_id' },
          pipeline: [
            {
              $match: {
                ...dimensionMatch,
                $expr: { $eq: ['$userId', '$$uid'] },
              },
            },
            { $sort: { clientTs: 1 } },
            { $limit: 1 },
            { $project: { appVersion: 1, platform: 1 } },
          ],
          as: 'firstEvent',
        },
      },
      {
        $addFields: {
          appVersion: {
            $ifNull: [{ $arrayElemAt: ['$firstEvent.appVersion', 0] }, null],
          },
          platform: {
            $ifNull: [{ $arrayElemAt: ['$firstEvent.platform', 0] }, null],
          },
        },
      },
      ...lookups,
      {
        $facet: {
          overall: [{ $group: { _id: null, ...cohortAccumulators } }],
          byAppVersion: [
            { $match: { appVersion: { $ne: null } } },
            { $group: { _id: '$appVersion', ...cohortAccumulators } },
          ],
          byPlatform: [
            { $match: { platform: { $ne: null } } },
            { $group: { _id: '$platform', ...cohortAccumulators } },
          ],
        },
      },
    ]);

    const readOffsets = (row: Record<string, number>) =>
      offsets.map((offset) => ({
        offset,
        cohortUsers: row?.[`cohort_${offset}`] ?? 0,
        retained: row?.[`retained_${offset}`] ?? 0,
      }));

    return {
      overall: readOffsets(result?.overall?.[0] ?? {}),
      byAppVersion: (result?.byAppVersion ?? []).flatMap((row: any) =>
        readOffsets(row).map((point) => ({
          appVersion: String(row._id),
          ...point,
        })),
      ),
      byPlatform: (result?.byPlatform ?? []).flatMap((row: any) =>
        readOffsets(row).map((point) => ({
          platform: String(row._id),
          ...point,
        })),
      ),
    };
  }

  // ------------------------------------------------------------- sessions

  /**
   * Sessions are rebuilt by grouping on `sessionId` — the app already cut them
   * on a 30-minute gap (GA4's own rule) before sending, so there is no
   * sessionisation to redo here.
   */
  async sessionStats(filter: IDashboardFilter): Promise<{
    totals: {
      sessions: number;
      engagedSessions: number;
      totalDurationMs: number;
      totalEvents: number;
      totalScreens: number;
      activeUsers: number;
    };
    daily: { date: string; sessions: number; engagedSessions: number }[];
    depthBuckets: IDepthBucket[];
    durations: {
      count: number;
      medianMs: number | null;
      p25Ms: number | null;
      p75Ms: number | null;
      engagedMedianMs: number | null;
      longSessions: number;
      bounces: number;
    };
    byWeekday: IWeekdayDuration[];
    byAppVersion: IVersionDuration[];
  }> {
    const [result] = await this.eventModel.aggregate([
      { $match: this.buildMatch(filter) },
      {
        $group: {
          _id: '$sessionId',
          userId: { $first: '$userId' },
          appVersion: { $first: '$appVersion' },
          startAt: { $min: '$clientTs' },
          endAt: { $max: '$clientTs' },
          events: { $sum: 1 },
          screens: {
            $sum: {
              $cond: [{ $eq: ['$kind', UserEventKind.SCREEN] }, 1, 0],
            },
          },
        },
      },
      { $addFields: { durationMs: { $subtract: ['$endAt', '$startAt'] } } },
      {
        $addFields: {
          engaged: {
            $or: [
              { $gte: ['$durationMs', ENGAGED_SESSION_MIN_MS] },
              { $gte: ['$screens', ENGAGED_SESSION_MIN_SCREENS] },
            ],
          },
          date: this.dateField('startAt', filter.timezone),
          weekday: {
            $dayOfWeek: { date: '$startAt', timezone: filter.timezone },
          },
        },
      },
      {
        $facet: {
          totals: [
            {
              $group: {
                _id: null,
                sessions: { $sum: 1 },
                engagedSessions: { $sum: { $cond: ['$engaged', 1, 0] } },
                totalDurationMs: { $sum: '$durationMs' },
                totalEvents: { $sum: '$events' },
                totalScreens: { $sum: '$screens' },
                users: { $addToSet: '$userId' },
              },
            },
            {
              $project: {
                _id: 0,
                sessions: 1,
                engagedSessions: 1,
                totalDurationMs: 1,
                totalEvents: 1,
                totalScreens: 1,
                activeUsers: { $size: '$users' },
              },
            },
          ],
          daily: [
            {
              $group: {
                _id: '$date',
                sessions: { $sum: 1 },
                engagedSessions: { $sum: { $cond: ['$engaged', 1, 0] } },
              },
            },
            { $sort: { _id: 1 } },
          ],
          depth: [
            {
              $bucket: {
                groupBy: '$events',
                boundaries: [...SESSION_DEPTH_BUCKETS],
                default: 'overflow',
                output: { sessions: { $sum: 1 } },
              },
            },
          ],
          // Sorting before the group is what makes the percentile indexes below
          // valid: `$push` keeps input order, so the array is already sorted.
          durations: [
            { $sort: { durationMs: 1 } },
            {
              $group: {
                _id: null,
                values: { $push: '$durationMs' },
                count: { $sum: 1 },
                longSessions: {
                  $sum: {
                    $cond: [{ $gte: ['$durationMs', LONG_SESSION_MS] }, 1, 0],
                  },
                },
                bounces: {
                  $sum: {
                    $cond: [{ $lt: ['$durationMs', BOUNCE_SESSION_MS] }, 1, 0],
                  },
                },
              },
            },
            {
              $project: {
                _id: 0,
                count: 1,
                longSessions: 1,
                bounces: 1,
                p25: this.percentile('values', 'count', DURATION_PERCENTILES.p25),
                median: this.percentile(
                  'values',
                  'count',
                  DURATION_PERCENTILES.median,
                ),
                p75: this.percentile('values', 'count', DURATION_PERCENTILES.p75),
              },
            },
          ],
          engagedDurations: [
            { $match: { engaged: true } },
            { $sort: { durationMs: 1 } },
            {
              $group: {
                _id: null,
                values: { $push: '$durationMs' },
                count: { $sum: 1 },
              },
            },
            {
              $project: {
                _id: 0,
                median: this.percentile(
                  'values',
                  'count',
                  DURATION_PERCENTILES.median,
                ),
              },
            },
          ],
          byWeekday: [
            { $sort: { durationMs: 1 } },
            {
              $group: {
                _id: '$weekday',
                values: { $push: '$durationMs' },
                count: { $sum: 1 },
              },
            },
            {
              $project: {
                sessions: '$count',
                median: this.percentile(
                  'values',
                  'count',
                  DURATION_PERCENTILES.median,
                ),
              },
            },
            { $sort: { _id: 1 } },
          ],
          byAppVersion: [
            { $match: { appVersion: { $type: 'string', $ne: '' } } },
            { $sort: { durationMs: 1 } },
            {
              $group: {
                _id: '$appVersion',
                values: { $push: '$durationMs' },
                count: { $sum: 1 },
              },
            },
            {
              $project: {
                sessions: '$count',
                median: this.percentile(
                  'values',
                  'count',
                  DURATION_PERCENTILES.median,
                ),
              },
            },
            { $sort: { _id: -1 } },
          ],
        },
      },
    ]);

    const edges: number[] = [...SESSION_DEPTH_BUCKETS];
    const depthRows: { _id: number | string; sessions: number }[] =
      result?.depth ?? [];
    const durationRow = result?.durations?.[0];

    return {
      totals: result?.totals?.[0] ?? {
        sessions: 0,
        engagedSessions: 0,
        totalDurationMs: 0,
        totalEvents: 0,
        totalScreens: 0,
        activeUsers: 0,
      },
      daily: (result?.daily ?? []).map((row: any) => ({
        date: row._id,
        sessions: row.sessions,
        engagedSessions: row.engagedSessions,
      })),
      depthBuckets: depthRows.map((row) => {
        if (row._id === 'overflow') {
          return {
            from: edges[edges.length - 1],
            to: null,
            sessions: row.sessions,
          };
        }
        const index = edges.indexOf(row._id as number);
        return {
          from: row._id as number,
          to: index >= 0 && index < edges.length - 1 ? edges[index + 1] - 1 : null,
          sessions: row.sessions,
        };
      }),
      durations: {
        count: durationRow?.count ?? 0,
        medianMs: durationRow?.median ?? null,
        p25Ms: durationRow?.p25 ?? null,
        p75Ms: durationRow?.p75 ?? null,
        engagedMedianMs: result?.engagedDurations?.[0]?.median ?? null,
        longSessions: durationRow?.longSessions ?? 0,
        bounces: durationRow?.bounces ?? 0,
      },
      byWeekday: (result?.byWeekday ?? []).map((row: any) => ({
        weekday: row._id as number,
        medianMs: row.median ?? null,
        sessions: row.sessions,
      })),
      byAppVersion: (result?.byAppVersion ?? []).map((row: any) => ({
        appVersion: String(row._id),
        medianMs: row.median ?? null,
        sessions: row.sessions,
      })),
    };
  }

  /**
   * The four session-depth measures, per app version, in one pass.
   *
   * Sessions are rebuilt per (version, sessionId) so a metric like
   * "lessons finished per session" is a real per-session number rather than a
   * total divided by a total. `activeDays` comes back too, because
   * sessions-per-user is meaningless without knowing how many days it covers.
   */
  async versionDepth(
    filter: IDashboardFilter,
    completionEvent: string,
  ): Promise<
    {
      appVersion: string;
      sessions: number;
      users: number;
      completers: number;
      activeDays: number;
      completions: number;
      medianMs: number | null;
    }[]
  > {
    const rows = await this.eventModel.aggregate([
      {
        $match: {
          ...this.buildMatch(filter),
          appVersion: { $type: 'string', $ne: '' },
        },
      },
      {
        $group: {
          _id: { appVersion: '$appVersion', sessionId: '$sessionId' },
          userId: { $first: '$userId' },
          startAt: { $min: '$clientTs' },
          endAt: { $max: '$clientTs' },
          completions: {
            $sum: { $cond: [{ $eq: ['$name', completionEvent] }, 1, 0] },
          },
        },
      },
      {
        $addFields: {
          durationMs: { $subtract: ['$endAt', '$startAt'] },
          date: this.dateField('startAt', filter.timezone),
        },
      },
      // Sorted before the group so the percentile index below is valid.
      { $sort: { durationMs: 1 } },
      {
        $group: {
          _id: '$_id.appVersion',
          sessions: { $sum: 1 },
          values: { $push: '$durationMs' },
          count: { $sum: 1 },
          completions: { $sum: '$completions' },
          users: { $addToSet: '$userId' },
          // `$$REMOVE` drops the entry entirely instead of adding a null, so
          // the set really is "users who finished something".
          completerUsers: {
            $addToSet: {
              $cond: [{ $gt: ['$completions', 0] }, '$userId', '$$REMOVE'],
            },
          },
          days: { $addToSet: '$date' },
        },
      },
      {
        $project: {
          sessions: 1,
          completions: 1,
          users: { $size: '$users' },
          completers: { $size: '$completerUsers' },
          activeDays: { $size: '$days' },
          medianMs: this.percentile(
            'values',
            'count',
            DURATION_PERCENTILES.median,
          ),
        },
      },
    ]);

    return rows.map((row) => ({
      appVersion: String(row._id),
      sessions: row.sessions,
      users: row.users,
      completers: row.completers,
      activeDays: row.activeDays,
      completions: row.completions,
      medianMs: row.medianMs ?? null,
    }));
  }

  /**
   * Nth-percentile of an already-sorted array field.
   *
   * `$percentile` and `$median` would be the obvious tools but they need
   * MongoDB 7; this indexes into the sorted array instead and works anywhere.
   * The index is clamped so a single-element array returns that element rather
   * than reading past the end.
   */
  private percentile(valuesField: string, countField: string, q: number) {
    return percentileOf(valuesField, countField, q);
  }

  /**
   * Distinct users per weekday × hour, twice: all activity, and only the
   * reading flow.
   *
   * Counted as people rather than events so one insomniac replaying a lesson
   * cannot light up a cell nobody else was in.
   */
  async activityHeatmap(filter: IDashboardFilter): Promise<{
    all: IHeatmapCell[];
    learning: IHeatmapCell[];
  }> {
    const slot = {
      weekday: { $dayOfWeek: { date: '$clientTs', timezone: filter.timezone } },
      hour: { $hour: { date: '$clientTs', timezone: filter.timezone } },
    };

    const branch = (extraMatch?: Record<string, unknown>) => [
      ...(extraMatch ? [{ $match: extraMatch }] : []),
      { $group: { _id: { ...slot, userId: '$userId' } } },
      {
        $group: {
          _id: { weekday: '$_id.weekday', hour: '$_id.hour' },
          users: { $sum: 1 },
        },
      },
    ];

    const [result] = await this.eventModel.aggregate([
      { $match: this.buildMatch(filter) },
      {
        $facet: {
          all: branch(),
          learning: branch({ name: { $regex: LEARNING_EVENT_PATTERN } }),
        },
      },
    ]);

    const toCells = (rows: any[]): IHeatmapCell[] =>
      (rows ?? []).map((row) => ({
        weekday: row._id.weekday,
        hour: row._id.hour,
        users: row.users,
      }));

    return {
      all: toCells(result?.all),
      learning: toCells(result?.learning),
    };
  }

  /**
   * Events and sessions per hour of day. A session that spans two hours is
   * counted in both — that is the intent, since the question is "when are
   * people studying", not "when did a session start".
   */
  async hourlyActivity(filter: IDashboardFilter): Promise<IHourPoint[]> {
    const rows = await this.eventModel.aggregate([
      { $match: this.buildMatch(filter) },
      {
        $group: {
          _id: {
            hour: { $hour: { date: '$clientTs', timezone: filter.timezone } },
            sessionId: '$sessionId',
          },
          events: { $sum: 1 },
        },
      },
      {
        $group: {
          _id: '$_id.hour',
          sessions: { $sum: 1 },
          events: { $sum: '$events' },
        },
      },
      { $sort: { _id: 1 } },
    ]);

    const byHour = new Map<number, { sessions: number; events: number }>(
      rows.map((row) => [
        row._id as number,
        { sessions: row.sessions, events: row.events },
      ]),
    );

    // Always 24 points: a chart with holes in it reads as missing data rather
    // than as a quiet hour.
    return Array.from({ length: 24 }, (_, hour) => ({
      hour,
      sessions: byHour.get(hour)?.sessions ?? 0,
      events: byHour.get(hour)?.events ?? 0,
    }));
  }

  // ----------------------------------------------------------- onboarding

  async onboardingFunnel(filter: IDashboardFilter): Promise<{
    steps: { event: string; users: number }[];
    started: number;
    completed: number;
  }> {
    const match = {
      ...this.buildMatch(filter),
      name: { $regex: `^${ONBOARDING_EVENT_PREFIX}` },
    };

    const [result] = await this.eventModel.aggregate([
      { $match: match },
      {
        $facet: {
          steps: [
            { $match: { name: { $regex: `${ONBOARDING_STEP_SUFFIX}$` } } },
            { $group: { _id: { name: '$name', userId: '$userId' } } },
            { $group: { _id: '$_id.name', users: { $sum: 1 } } },
            // A funnel only ever loses people, so ordering by distinct users
            // reproduces the step order without hardcoding the flow here —
            // onboarding is reordered often, and that must not need an API
            // deploy.
            { $sort: { users: -1, _id: 1 } },
          ],
          started: [{ $group: { _id: '$userId' } }, { $count: 'total' }],
          completed: [
            { $match: { name: ONBOARDING_COMPLETED_STEP } },
            { $group: { _id: '$userId' } },
            { $count: 'total' },
          ],
        },
      },
    ]);

    return {
      steps: (result?.steps ?? []).map((row: any) => ({
        event: row._id,
        users: row.users,
      })),
      started: result?.started?.[0]?.total ?? 0,
      completed: result?.completed?.[0]?.total ?? 0,
    };
  }

  // ------------------------------------------------------------- learning

  /** Distinct users and raw event counts for a fixed set of event names. */
  async eventTotals(
    filter: IDashboardFilter,
    events: string[],
  ): Promise<Record<string, { users: number; events: number }>> {
    if (!events.length) return {};

    const rows = await this.eventModel.aggregate([
      { $match: { ...this.buildMatch(filter), name: { $in: events } } },
      {
        $group: {
          _id: { name: '$name', userId: '$userId' },
          count: { $sum: 1 },
        },
      },
      {
        $group: {
          _id: '$_id.name',
          users: { $sum: 1 },
          events: { $sum: '$count' },
        },
      },
    ]);

    return rows.reduce(
      (acc, row) => ({
        ...acc,
        [row._id]: { users: row.users, events: row.events },
      }),
      {} as Record<string, { users: number; events: number }>,
    );
  }

  /** Distinct users per (event, platform) — the per-OS split on funnel steps. */
  async eventTotalsByPlatform(
    filter: IDashboardFilter,
    events: string[],
  ): Promise<Record<string, INameValue[]>> {
    if (!events.length) return {};

    const rows = await this.eventModel.aggregate([
      { $match: { ...this.buildMatch(filter), name: { $in: events } } },
      {
        $group: {
          _id: { name: '$name', platform: '$platform', userId: '$userId' },
        },
      },
      {
        $group: {
          _id: { name: '$_id.name', platform: '$_id.platform' },
          users: { $sum: 1 },
        },
      },
      { $sort: { users: -1 } },
    ]);

    return rows.reduce((acc, row) => {
      if (!row._id.platform) return acc;
      const list = acc[row._id.name] ?? [];
      list.push({ name: String(row._id.platform), value: row.users });
      return { ...acc, [row._id.name]: list };
    }, {} as Record<string, INameValue[]>);
  }

  /** Total screen-view events — raw volume, not distinct people. */
  async countScreenViews(filter: IDashboardFilter): Promise<number> {
    const [row] = await this.eventModel.aggregate([
      {
        $match: { ...this.buildMatch(filter), kind: UserEventKind.SCREEN },
      },
      { $count: 'total' },
    ]);

    return row?.total ?? 0;
  }

  /**
   * Top courses for several events at once — "chosen first", "opened", "read",
   * "completed" are four different questions about the same catalogue.
   *
   * One pass rather than four: the events share a match and a grouping key, so
   * splitting them into separate queries would just re-scan the same range.
   */
  async topContentByEvent(
    filter: IDashboardFilter,
    events: string[],
    idField: string,
    nameField: string,
  ): Promise<Record<string, ITopContentRow[]>> {
    if (!events.length) return {};

    const rows = await this.eventModel.aggregate([
      {
        $match: {
          ...this.buildMatch(filter),
          name: { $in: events },
          [nameField]: { $type: 'string', $ne: '' },
        },
      },
      {
        $group: {
          _id: {
            event: '$name',
            name: `$${nameField}`,
            userId: '$userId',
          },
          contentId: { $first: `$${idField}` },
          count: { $sum: 1 },
        },
      },
      {
        $group: {
          _id: { event: '$_id.event', name: '$_id.name' },
          contentId: { $first: '$contentId' },
          users: { $sum: 1 },
          events: { $sum: '$count' },
        },
      },
      { $sort: { users: -1, events: -1 } },
    ]);

    return rows.reduce((acc, row) => {
      const list = acc[row._id.event] ?? [];
      list.push({
        id: row.contentId ? String(row.contentId) : null,
        name: String(row._id.name),
        users: row.users,
        events: row.events,
      });
      return { ...acc, [row._id.event]: list };
    }, {} as Record<string, ITopContentRow[]>);
  }

  /**
   * Which courses each age band reads and finishes.
   *
   * Age lives on the user document, not on the event, so this collapses to one
   * row per (user, course, event) *before* joining — the join then runs over a
   * few thousand rows instead of every event in the range.
   */
  async contentByAge(
    filter: IDashboardFilter,
    events: string[],
    idField: string,
    nameField: string,
  ): Promise<{
    rows: { age: string; event: string; name: string; id: string | null; users: number }[];
    usersByAge: INameValue[];
  }> {
    if (!events.length) return { rows: [], usersByAge: [] };

    const [result] = await this.eventModel.aggregate([
      {
        $match: {
          ...this.buildMatch(filter),
          name: { $in: events },
          [nameField]: { $type: 'string', $ne: '' },
        },
      },
      {
        $group: {
          _id: {
            userId: '$userId',
            event: '$name',
            name: `$${nameField}`,
          },
          contentId: { $first: `$${idField}` },
        },
      },
      {
        $lookup: {
          from: 'users',
          localField: '_id.userId',
          foreignField: '_id',
          as: 'user',
        },
      },
      {
        $addFields: {
          age: { $ifNull: [{ $arrayElemAt: ['$user.age', 0] }, null] },
        },
      },
      { $match: { age: { $type: 'string', $ne: '' } } },
      {
        $facet: {
          rows: [
            {
              $group: {
                _id: { age: '$age', event: '$_id.event', name: '$_id.name' },
                contentId: { $first: '$contentId' },
                users: { $sum: 1 },
              },
            },
            { $sort: { users: -1 } },
          ],
          usersByAge: [
            { $group: { _id: { age: '$age', userId: '$_id.userId' } } },
            { $group: { _id: '$_id.age', users: { $sum: 1 } } },
            { $sort: { users: -1 } },
          ],
        },
      },
    ]);

    return {
      rows: (result?.rows ?? []).map((row: any) => ({
        age: String(row._id.age),
        event: String(row._id.event),
        name: String(row._id.name),
        id: row.contentId ? String(row.contentId) : null,
        users: row.users,
      })),
      usersByAge: (result?.usersByAge ?? []).map((row: any) => ({
        name: String(row._id),
        value: row.users,
      })),
    };
  }

  async dailyEventUsers(
    filter: IDashboardFilter,
    events: string[],
  ): Promise<{ date: string; event: string; users: number }[]> {
    if (!events.length) return [];

    const rows = await this.eventModel.aggregate([
      { $match: { ...this.buildMatch(filter), name: { $in: events } } },
      {
        $group: {
          _id: {
            date: this.dateField('clientTs', filter.timezone),
            name: '$name',
            userId: '$userId',
          },
        },
      },
      {
        $group: {
          _id: { date: '$_id.date', name: '$_id.name' },
          users: { $sum: 1 },
        },
      },
      { $sort: { '_id.date': 1 } },
    ]);

    return rows.map((row) => ({
      date: row._id.date,
      event: row._id.name,
      users: row.users,
    }));
  }

  /**
   * Top courses / skillsets by distinct readers.
   *
   * Grouped on the *param* the app already sends with every content event, so
   * no join and no extra config: `params.course_name` is written by
   * `LessonTracking.keypointParams()` on the client.
   */
  async topContent(
    filter: IDashboardFilter,
    idField: string,
    nameField: string,
    limit = TOP_LIST_LIMIT,
  ): Promise<ITopContentRow[]> {
    const rows = await this.eventModel.aggregate([
      {
        $match: {
          ...this.buildMatch(filter),
          [nameField]: { $type: 'string', $ne: '' },
        },
      },
      {
        $group: {
          _id: { name: `$${nameField}`, userId: '$userId' },
          contentId: { $first: `$${idField}` },
          count: { $sum: 1 },
        },
      },
      {
        $group: {
          _id: '$_id.name',
          contentId: { $first: '$contentId' },
          users: { $sum: 1 },
          events: { $sum: '$count' },
        },
      },
      { $sort: { users: -1, events: -1 } },
      { $limit: limit },
    ]);

    return rows.map((row) => ({
      id: row.contentId ? String(row.contentId) : null,
      name: String(row._id),
      users: row.users,
      events: row.events,
    }));
  }

  // -------------------------------------------------------------- rollup

  /**
   * Everything [AnalyticsRollupService] needs to write one day down, in a
   * single pass over that day's events.
   */
  async rollupDay(
    dayStart: Date,
    dayEnd: Date,
    appEnv: string,
    timezone: string,
  ): Promise<{
    activeUserIds: Types.ObjectId[];
    sessions: number;
    engagedSessions: number;
    events: number;
    totalDurationMs: number;
    hourlyEvents: number[];
    eventUsers: Record<string, number>;
    eventCounts: Record<string, number>;
  }> {
    const match: FilterQuery<UserEvent> = {
      clientTs: { $gte: dayStart, $lt: dayEnd },
      appEnv,
    };

    const [result] = await this.eventModel.aggregate([
      { $match: match },
      {
        $facet: {
          users: [{ $group: { _id: '$userId' } }],
          sessions: [
            {
              $group: {
                _id: '$sessionId',
                startAt: { $min: '$clientTs' },
                endAt: { $max: '$clientTs' },
                screens: {
                  $sum: {
                    $cond: [{ $eq: ['$kind', UserEventKind.SCREEN] }, 1, 0],
                  },
                },
              },
            },
            {
              $addFields: { durationMs: { $subtract: ['$endAt', '$startAt'] } },
            },
            {
              $group: {
                _id: null,
                sessions: { $sum: 1 },
                totalDurationMs: { $sum: '$durationMs' },
                engagedSessions: {
                  $sum: {
                    $cond: [
                      {
                        $or: [
                          { $gte: ['$durationMs', ENGAGED_SESSION_MIN_MS] },
                          { $gte: ['$screens', ENGAGED_SESSION_MIN_SCREENS] },
                        ],
                      },
                      1,
                      0,
                    ],
                  },
                },
              },
            },
          ],
          hourly: [
            {
              $group: {
                _id: { $hour: { date: '$clientTs', timezone } },
                events: { $sum: 1 },
              },
            },
          ],
          byEvent: [
            {
              $group: {
                _id: { name: '$name', userId: '$userId' },
                count: { $sum: 1 },
              },
            },
            {
              $group: {
                _id: '$_id.name',
                users: { $sum: 1 },
                events: { $sum: '$count' },
              },
            },
          ],
        },
      },
    ]);

    const hourlyEvents = new Array(24).fill(0);
    for (const row of result?.hourly ?? []) {
      hourlyEvents[row._id as number] = row.events;
    }

    const eventUsers: Record<string, number> = {};
    const eventCounts: Record<string, number> = {};
    for (const row of result?.byEvent ?? []) {
      eventUsers[row._id] = row.users;
      eventCounts[row._id] = row.events;
    }

    const sessionRow = result?.sessions?.[0];

    return {
      activeUserIds: (result?.users ?? []).map((row: any) => row._id),
      sessions: sessionRow?.sessions ?? 0,
      engagedSessions: sessionRow?.engagedSessions ?? 0,
      events: Object.values(eventCounts).reduce((sum, n) => sum + n, 0),
      totalDurationMs: sessionRow?.totalDurationMs ?? 0,
      hourlyEvents,
      eventUsers,
      eventCounts,
    };
  }

  /** Users created inside the rollup's day — the cohort seed for retention. */
  async newUserIdsBetween(from: Date, to: Date): Promise<Types.ObjectId[]> {
    const rows = await this.userModel
      .find({ createdAt: { $gte: from, $lt: to } }, { _id: 1 })
      .lean();

    return rows.map((row) => row._id as Types.ObjectId);
  }
}
