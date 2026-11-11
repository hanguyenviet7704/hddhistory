import { Injectable } from '@nestjs/common';

import {
  ACTIVE_WINDOWS,
  AGE_INTEREST_LIMIT,
  COUNTRY_LIST_LIMIT,
  COURSE_ID_PARAM,
  COURSE_RANKINGS,
  COURSE_RANKING_LIMIT,
  COURSE_NAME_PARAM,
  LEARNING_MILESTONES,
  RETENTION_OFFSETS,
  SKILL_ID_PARAM,
  SKILL_NAME_PARAM,
} from './constant/dashboard.constant';
import {
  previousDashboardPeriod,
  rateOf,
  resolveDashboardFilter,
  toDashboardRange,
} from './dashboard-period.helper';
import { GetDashboardDto } from './dto/get-dashboard.dto';
import {
  IDashboardFilter,
  IDashboardRange,
  IFunnelStep,
  ILearningPage,
  IOnboardingPage,
  IOverviewPage,
  IRetentionPoint,
  ISessionTotals,
  ISessionsPage,
  IUserTotals,
  IUsersPage,
} from './interface/dashboard.interface';
import { AnalyticsDashboardRepository } from './repository/analytics-dashboard.repository';

const DAY_MS = 24 * 60 * 60 * 1000;

/**
 * Assembles the admin product dashboard.
 *
 * Everything this class adds on top of the repository is interpretation: what
 * "the previous period" means, when a rate is a number and when it has to stay
 * null, and which of the raw counts belong on which page. The rule it follows
 * throughout: **a rate with no denominator is `null`, never 0** — printing 0%
 * for "we have not measured this yet" is how a dashboard lies.
 */
@Injectable()
export class AnalyticsDashboardService {
  constructor(private readonly repository: AnalyticsDashboardRepository) {}

  // ------------------------------------------------------------- plumbing

  // The four below live in `dashboard-period.helper` so that this page and the
  // Coach page cannot disagree about where the comparison window starts. Kept
  // as methods rather than rewriting every `this.` call site in this file.
  private resolveFilter(dto: GetDashboardDto): IDashboardFilter {
    return resolveDashboardFilter(dto);
  }

  private toRange(filter: IDashboardFilter): IDashboardRange {
    return toDashboardRange(filter);
  }

  private previousFilter(filter: IDashboardFilter): IDashboardFilter {
    return previousDashboardPeriod(filter);
  }

  private rate(numerator: number, denominator: number): number | null {
    return rateOf(numerator, denominator);
  }

  /** Relative change, or null when there is no base to change from. */
  private growth(from: number | null, to: number | null): number | null {
    if (from === null || to === null || from === 0) return null;
    return (to - from) / from;
  }

  /**
   * Sorts "1.4.10" after "1.4.9", which a plain string sort gets wrong the
   * moment a version part reaches double digits.
   */
  private compareVersions(a: string, b: string): number {
    const parts = (value: string) =>
      value.split('.').map((part) => Number(part.replace(/\D/g, '')) || 0);
    const left = parts(a);
    const right = parts(b);

    for (let i = 0; i < Math.max(left.length, right.length); i++) {
      const diff = (left[i] ?? 0) - (right[i] ?? 0);
      if (diff !== 0) return diff;
    }
    return 0;
  }

  private toRetentionPoints(
    rows: { offset: number; cohortUsers: number; retained: number }[],
  ): IRetentionPoint[] {
    return rows.map((row) => ({
      offset: row.offset,
      cohortUsers: row.cohortUsers,
      retainedUsers: row.retained,
      rate: this.rate(row.retained, row.cohortUsers),
    }));
  }

  private async userTotals(filter: IDashboardFilter): Promise<IUserTotals> {
    const [active, newUsers] = await Promise.all([
      this.repository.countActiveUsers(filter),
      this.repository.countNewUsers(filter.from, filter.to),
    ]);

    return {
      active,
      new: newUsers,
      // Someone active who did not sign up in this period came back to us.
      // Clamped at 0: a user can sign up inside the range and never open the
      // app, which would otherwise push this negative.
      returning: Math.max(0, active - newUsers),
    };
  }

  private toSessionTotals(stats: {
    totals: {
      sessions: number;
      engagedSessions: number;
      totalDurationMs: number;
      totalEvents: number;
      totalScreens: number;
      activeUsers: number;
    };
  }): ISessionTotals {
    const { totals } = stats;

    return {
      sessions: totals.sessions,
      engagedSessions: totals.engagedSessions,
      engagementRate: this.rate(totals.engagedSessions, totals.sessions),
      avgDurationMs: totals.sessions
        ? Math.round(totals.totalDurationMs / totals.sessions)
        : 0,
      avgEvents: totals.sessions
        ? Number((totals.totalEvents / totals.sessions).toFixed(1))
        : 0,
      avgScreens: totals.sessions
        ? Number((totals.totalScreens / totals.sessions).toFixed(1))
        : 0,
      activeUsers: totals.activeUsers,
      sessionsPerUser: totals.activeUsers
        ? Number((totals.sessions / totals.activeUsers).toFixed(2))
        : null,
    };
  }

  /**
   * Turn per-step user counts into a funnel.
   *
   * The first step is the denominator for every pass rate; drops are measured
   * against the step before, which is the number anyone reading "mất 145
   * người ở màn chào mừng" actually wants.
   */
  private toFunnel(steps: { event: string; users: number }[]): IFunnelStep[] {
    const first = steps[0]?.users ?? 0;

    return steps.map((step, index) => {
      const previous = index === 0 ? step.users : steps[index - 1].users;
      const dropUsers = Math.max(0, previous - step.users);

      return {
        event: step.event,
        users: step.users,
        passRate: this.rate(step.users, first),
        dropUsers,
        dropRate: index === 0 ? null : this.rate(dropUsers, previous),
      };
    });
  }

  // ----------------------------------------------------------- users page

  async getUsers(dto: GetDashboardDto): Promise<IUsersPage> {
    const filter = this.resolveFilter(dto);
    const previous = dto.compare ? this.previousFilter(filter) : null;
    const now = new Date();

    // Rolling windows anchored at the end of the range, not at "now": a report
    // for last month must show that month's MAU, not today's.
    const windowEnd = filter.to;
    const dayStart = new Date(windowEnd.getTime() - DAY_MS + 1);
    const wauStart = new Date(
      windowEnd.getTime() - ACTIVE_WINDOWS.wau * DAY_MS + 1,
    );
    const mauStart = new Date(
      windowEnd.getTime() - ACTIVE_WINDOWS.mau * DAY_MS + 1,
    );
    const mauAtStartFrom = new Date(
      filter.from.getTime() - ACTIVE_WINDOWS.mau * DAY_MS + 1,
    );

    const [
      totals,
      previousTotals,
      dailyActive,
      dailyNew,
      dailyByPlatform,
      retention,
      byPlatform,
      byAppVersion,
      demographics,
      dau,
      wau,
      mau,
      mauAtStart,
    ] = await Promise.all([
      this.userTotals(filter),
      previous ? this.userTotals(previous) : null,
      this.repository.dailyActiveUsers(filter),
      this.repository.dailyNewUsers(filter.from, filter.to, filter.timezone),
      this.repository.dailyActiveUsersByPlatform(filter),
      this.repository.retentionCohorts(filter, [...RETENTION_OFFSETS], now),
      this.repository.usersByDimension(filter, 'platform'),
      this.repository.usersByDimension(filter, 'appVersion'),
      this.repository.demographics(
        filter.from,
        filter.to,
        COUNTRY_LIST_LIMIT,
      ),
      this.repository.countActiveUsersInWindow(filter, dayStart, windowEnd),
      this.repository.countActiveUsersInWindow(filter, wauStart, windowEnd),
      this.repository.countActiveUsersInWindow(filter, mauStart, windowEnd),
      this.repository.countActiveUsersInWindow(
        filter,
        mauAtStartFrom,
        filter.from,
      ),
    ]);

    const newByDate = new Map(dailyNew.map((row) => [row.date, row.users]));
    const dates = new Set([
      ...dailyActive.map((row) => row.date),
      ...dailyNew.map((row) => row.date),
    ]);
    const activeByDate = new Map(
      dailyActive.map((row) => [row.date, row.users]),
    );

    const groupCohorts = <T extends { offset: number }>(
      rows: T[],
      key: (row: T) => string,
    ) => {
      const grouped = new Map<string, T[]>();
      for (const row of rows) {
        const list = grouped.get(key(row)) ?? [];
        list.push(row);
        grouped.set(key(row), list);
      }
      return grouped;
    };

    const byVersion = groupCohorts(retention.byAppVersion, (r) => r.appVersion);
    const byPlatformCohorts = groupCohorts(
      retention.byPlatform,
      (r) => r.platform,
    );

    return {
      range: this.toRange(filter),
      compareRange: previous ? this.toRange(previous) : null,
      totals,
      previousTotals,
      daily: Array.from(dates)
        .sort()
        .map((date) => ({
          date,
          active: activeByDate.get(date) ?? 0,
          new: newByDate.get(date) ?? 0,
        })),
      dailyByPlatform,
      activeWindows: {
        dau,
        wau,
        mau,
        mauAtStart,
        stickiness: this.rate(dau, mau),
        dauDate: windowEnd.toLocaleDateString('en-CA', {
          timeZone: filter.timezone,
        }),
      },
      retention: this.toRetentionPoints(retention.overall),
      retentionByAppVersion: Array.from(byVersion.entries())
        .map(([appVersion, points]) => ({
          appVersion,
          points: this.toRetentionPoints(points),
        }))
        .sort((a, b) => b.appVersion.localeCompare(a.appVersion)),
      retentionByPlatform: Array.from(byPlatformCohorts.entries())
        .map(([platform, points]) => ({
          platform,
          points: this.toRetentionPoints(points),
        }))
        .sort((a, b) => a.platform.localeCompare(b.platform)),
      byPlatform,
      byAppVersion,
      demographics: {
        ...demographics,
        // An empty list here means the field is not collected, not that the
        // query failed — the panel says so instead of drawing an empty chart.
        hasCountryData: demographics.byCountry.length > 0,
        hasAgeData: demographics.byAge.length > 0,
      },
    };
  }

  // -------------------------------------------------------- sessions page

  async getSessions(dto: GetDashboardDto): Promise<ISessionsPage> {
    const filter = this.resolveFilter(dto);
    const previous = dto.compare ? this.previousFilter(filter) : null;

    const [stats, previousStats, hourly, heatmap] = await Promise.all([
      this.repository.sessionStats(filter),
      previous ? this.repository.sessionStats(previous) : null,
      this.repository.hourlyActivity(filter),
      this.repository.activityHeatmap(filter),
    ]);

    const { durations } = stats;

    return {
      range: this.toRange(filter),
      compareRange: previous ? this.toRange(previous) : null,
      totals: this.toSessionTotals(stats),
      previousTotals: previousStats
        ? this.toSessionTotals(previousStats)
        : null,
      daily: stats.daily,
      hourly,
      depthBuckets: stats.depthBuckets,
      durations: {
        medianMs: durations.medianMs,
        p25Ms: durations.p25Ms,
        p75Ms: durations.p75Ms,
        engagedMedianMs: durations.engagedMedianMs,
        longSessionRate: this.rate(durations.longSessions, durations.count),
        bounceRate: this.rate(durations.bounces, durations.count),
      },
      byWeekday: stats.byWeekday,
      byAppVersion: stats.byAppVersion,
      heatmap,
    };
  }

  // ------------------------------------------------------ onboarding page

  async getOnboarding(dto: GetDashboardDto): Promise<IOnboardingPage> {
    const filter = this.resolveFilter(dto);
    const previous = dto.compare ? this.previousFilter(filter) : null;

    const [current, previousFunnel] = await Promise.all([
      this.repository.onboardingFunnel(filter),
      previous ? this.repository.onboardingFunnel(previous) : null,
    ]);

    const steps = this.toFunnel(current.steps);

    return {
      range: this.toRange(filter),
      compareRange: previous ? this.toRange(previous) : null,
      started: current.started,
      completed: current.completed,
      completionRate: this.rate(current.completed, current.started),
      previous: previousFunnel
        ? {
            started: previousFunnel.started,
            completed: previousFunnel.completed,
            completionRate: this.rate(
              previousFunnel.completed,
              previousFunnel.started,
            ),
          }
        : null,
      steps,
      // The first step cannot "drop" anyone, so it is never the answer.
      biggestDrop:
        steps
          .slice(1)
          .sort((a, b) => b.dropUsers - a.dropUsers)
          .find((step) => step.dropUsers > 0) ?? null,
    };
  }

  // -------------------------------------------------------- learning page

  async getLearning(dto: GetDashboardDto): Promise<ILearningPage> {
    const filter = this.resolveFilter(dto);
    const previous = dto.compare ? this.previousFilter(filter) : null;
    const events = LEARNING_MILESTONES.map((milestone) => milestone.event);

    const rankingEvents = COURSE_RANKINGS.map((ranking) => ranking.event);
    const completionEvent = 'keypoint_complete_scr_view';
    const readEvent = 'keypoint_read_scr_view';

    const [
      totals,
      previousTotals,
      topCourses,
      topSkills,
      daily,
      byPlatform,
      screenViews,
      previousScreenViews,
      rankings,
      ageData,
    ] = await Promise.all([
      this.repository.eventTotals(filter, events),
      previous ? this.repository.eventTotals(previous, events) : null,
      this.repository.topContent(filter, COURSE_ID_PARAM, COURSE_NAME_PARAM),
      this.repository.topContent(filter, SKILL_ID_PARAM, SKILL_NAME_PARAM),
      this.repository.dailyEventUsers(filter, events),
      this.repository.eventTotalsByPlatform(filter, events),
      this.repository.countScreenViews(filter),
      previous ? this.repository.countScreenViews(previous) : null,
      this.repository.topContentByEvent(
        filter,
        rankingEvents,
        COURSE_ID_PARAM,
        COURSE_NAME_PARAM,
      ),
      this.repository.contentByAge(
        filter,
        [readEvent, completionEvent],
        COURSE_ID_PARAM,
        COURSE_NAME_PARAM,
      ),
    ]);

    const completionEvents = {
      keypoint: 'keypoint_complete_scr_view',
      lesson: 'lesson_finish_scr_view',
    };
    const dailyByDate = new Map<
      string,
      { keypointCompleted: number; lessonCompleted: number }
    >();
    for (const row of daily) {
      const entry = dailyByDate.get(row.date) ?? {
        keypointCompleted: 0,
        lessonCompleted: 0,
      };
      if (row.event === completionEvents.keypoint) {
        entry.keypointCompleted = row.users;
      }
      if (row.event === completionEvents.lesson) {
        entry.lessonCompleted = row.users;
      }
      dailyByDate.set(row.date, entry);
    }

    // The funnel's denominator is its first step, so every later step reads as
    // "of the people who got here at all, how many are still with us".
    const funnelBase = totals[LEARNING_MILESTONES[0].event]?.users ?? 0;

    const ageGroups = ageData.usersByAge.map((group) => {
      const forAge = (event: string) =>
        ageData.rows
          .filter((row) => row.age === group.name && row.event === event)
          .slice(0, AGE_INTEREST_LIMIT)
          .map((row) => ({
            id: row.id,
            name: row.name,
            users: row.users,
            events: row.users,
          }));

      return {
        age: group.name,
        users: group.value,
        interested: forAge(readEvent),
        completed: forAge(completionEvent),
      };
    });

    return {
      range: this.toRange(filter),
      compareRange: previous ? this.toRange(previous) : null,
      milestones: LEARNING_MILESTONES.map((milestone) => ({
        key: milestone.key,
        label: milestone.label,
        event: milestone.event,
        users: totals[milestone.event]?.users ?? 0,
        events: totals[milestone.event]?.events ?? 0,
        previousUsers: previousTotals
          ? (previousTotals[milestone.event]?.users ?? 0)
          : null,
        passRate: this.rate(totals[milestone.event]?.users ?? 0, funnelBase),
        byPlatform: byPlatform[milestone.event] ?? [],
      })),
      engagement: {
        screenViews,
        previousScreenViews,
        keypointCompletions: totals[completionEvent]?.events ?? 0,
        keypointCompletionUsers: totals[completionEvent]?.users ?? 0,
      },
      heroCourse: topCourses[0] ?? null,
      topCourses,
      topSkills,
      courseRankings: COURSE_RANKINGS.map((ranking) => ({
        key: ranking.key,
        label: ranking.label,
        hint: ranking.hint,
        event: ranking.event,
        rows: (rankings[ranking.event] ?? []).slice(0, COURSE_RANKING_LIMIT),
      })),
      byAge: ageGroups,
      daily: Array.from(dailyByDate.entries())
        .sort(([a], [b]) => a.localeCompare(b))
        .map(([date, value]) => ({ date, ...value })),
    };
  }

  // -------------------------------------------------------- overview page

  /**
   * The weekly-report screen: one headline number per area, each linking to the
   * page that explains it. Runs the same queries as those pages but only keeps
   * the top line, so it stays one round trip for the panel.
   */
  async getOverview(dto: GetDashboardDto): Promise<IOverviewPage> {
    const filter = this.resolveFilter(dto);
    const previous = dto.compare ? this.previousFilter(filter) : null;
    const now = new Date();
    const learningEvents = LEARNING_MILESTONES.map(
      (milestone) => milestone.event,
    );

    const [
      totals,
      previousTotals,
      retention,
      sessions,
      previousSessions,
      onboarding,
      learning,
      topCourses,
      topSkills,
      hourly,
      versionRows,
    ] = await Promise.all([
      this.userTotals(filter),
      previous ? this.userTotals(previous) : null,
      this.repository.retentionCohorts(filter, [...RETENTION_OFFSETS], now),
      this.repository.sessionStats(filter),
      previous ? this.repository.sessionStats(previous) : null,
      this.repository.onboardingFunnel(filter),
      this.repository.eventTotals(filter, learningEvents),
      this.repository.topContent(filter, COURSE_ID_PARAM, COURSE_NAME_PARAM, 1),
      this.repository.topContent(filter, SKILL_ID_PARAM, SKILL_NAME_PARAM, 1),
      this.repository.hourlyActivity(filter),
      this.repository.versionDepth(filter, 'keypoint_complete_scr_view'),
    ]);

    // Oldest first, so the release timeline reads left to right and the delta
    // is "from the baseline build to the newest one".
    const versions = [...versionRows]
      .sort((a, b) => this.compareVersions(a.appVersion, b.appVersion))
      .map((row) => ({
        appVersion: row.appVersion,
        sessions: row.sessions,
        users: row.users,
        sessionMedianMs: row.medianMs,
        lessonsPerSession: this.rate(row.completions, row.sessions),
        completionRate: this.rate(row.completers, row.users),
        sessionsPerUserPerDay:
          row.users && row.activeDays
            ? row.sessions / row.users / row.activeDays
            : null,
      }));

    const oldest = versions[0] ?? null;
    const newest = versions.length > 1 ? versions[versions.length - 1] : null;

    const funnel = this.toFunnel(onboarding.steps);
    const sessionTotals = this.toSessionTotals(sessions);

    return {
      range: this.toRange(filter),
      compareRange: previous ? this.toRange(previous) : null,
      users: { ...totals, previous: previousTotals },
      retention: this.toRetentionPoints(retention.overall),
      sessions: {
        total: sessionTotals.sessions,
        engagementRate: sessionTotals.engagementRate,
        previousTotal: previousSessions
          ? previousSessions.totals.sessions
          : null,
      },
      onboarding: {
        started: onboarding.started,
        completed: onboarding.completed,
        completionRate: this.rate(onboarding.completed, onboarding.started),
        biggestDrop:
          funnel
            .slice(1)
            .sort((a, b) => b.dropUsers - a.dropUsers)
            .find((step) => step.dropUsers > 0) ?? null,
      },
      learning: {
        roadmapOpened: learning['roadmap_scr_view']?.users ?? 0,
        lessonCompleted: learning['lesson_finish_scr_view']?.users ?? 0,
        topCourse: topCourses[0] ?? null,
        topSkill: topSkills[0] ?? null,
      },
      // Busiest hours first — the "khung giờ vàng" line reads the top few.
      peakHours: [...hourly].sort((a, b) => b.events - a.events).slice(0, 3),
      versionDepth: {
        versions,
        deltas: {
          sessionDurationPct: this.growth(
            oldest?.sessionMedianMs ?? null,
            newest?.sessionMedianMs ?? null,
          ),
          lessonsPerSessionPct: this.growth(
            oldest?.lessonsPerSession ?? null,
            newest?.lessonsPerSession ?? null,
          ),
          // Percentage points, not a percentage of a percentage: 67% → 80% is
          // "+13 điểm", and calling it "+19%" is how that number gets mangled.
          completionRatePoints:
            oldest?.completionRate != null && newest?.completionRate != null
              ? newest.completionRate - oldest.completionRate
              : null,
          sessionsPerUserPerDayPct: this.growth(
            oldest?.sessionsPerUserPerDay ?? null,
            newest?.sessionsPerUserPerDay ?? null,
          ),
          from: newest ? (oldest?.appVersion ?? null) : null,
          to: newest?.appVersion ?? null,
        },
      },
    };
  }
}
