import { Injectable, Logger } from '@nestjs/common';
import { Cron } from '@nestjs/schedule';

import { DEFAULT_APP_ENV, DEFAULT_TIMEZONE } from './constant/dashboard.constant';
import { AnalyticsDailyRepository } from './repository/analytics-daily.repository';
import { AnalyticsDashboardRepository } from './repository/analytics-dashboard.repository';

/**
 * The nightly memory of the product dashboard.
 *
 * `user_events` deletes itself after 90 days (TTL on `serverTs`), so anything
 * not written down before then is gone for good. This cron condenses each
 * finished day into one [AnalyticsDaily] document — counters plus the distinct
 * user ids, which is what keeps range-level user counts exact once the raw
 * events are gone.
 *
 * The dashboard still reads live events today; this runs from day one so that
 * by the time the raw window has rolled over, the history is already there.
 *
 * Failures are logged, never thrown: a rollup that dies must not take the app's
 * scheduler down with it, and the next run re-does the same day anyway
 * (`upsertDay` is idempotent).
 */
@Injectable()
export class AnalyticsRollupService {
  private readonly logger = new Logger(AnalyticsRollupService.name);

  /**
   * How many days back a run will repair. Yesterday is the point of the job;
   * the extra days catch late-arriving batches — the app persists its queue
   * across restarts, so events can land a day after they happened.
   */
  private static readonly BACKFILL_DAYS = 3;

  constructor(
    private readonly dashboardRepository: AnalyticsDashboardRepository,
    private readonly dailyRepository: AnalyticsDailyRepository,
  ) {}

  // 00:20 Vietnam time: after midnight so the day is closed, and off the hour
  // to stay clear of the segment snapshot at 00:15.
  @Cron('20 0 * * *', { timeZone: DEFAULT_TIMEZONE })
  async rollupRecentDays(): Promise<void> {
    const today = this.startOfDay(new Date());

    for (let back = 1; back <= AnalyticsRollupService.BACKFILL_DAYS; back++) {
      const dayStart = new Date(today.getTime() - back * 24 * 3600 * 1000);
      try {
        await this.rollupDay(dayStart);
      } catch (error: any) {
        this.logger.error(
          `Rollup failed for ${this.toDateKey(dayStart)}: ${error?.message}`,
          error?.stack,
        );
      }
    }
  }

  /** Condense a single day. Exposed so a backfill script can drive it. */
  async rollupDay(dayStart: Date, appEnv = DEFAULT_APP_ENV): Promise<void> {
    const dayEnd = new Date(dayStart.getTime() + 24 * 3600 * 1000);
    const date = this.toDateKey(dayStart);

    const [totals, newUserIds] = await Promise.all([
      this.dashboardRepository.rollupDay(
        dayStart,
        dayEnd,
        appEnv,
        DEFAULT_TIMEZONE,
      ),
      this.dashboardRepository.newUserIdsBetween(dayStart, dayEnd),
    ]);

    await this.dailyRepository.upsertDay(date, appEnv, {
      ...totals,
      newUserIds,
    });

    this.logger.log(
      `Rolled up ${date} (${appEnv}): ${totals.activeUserIds.length} users, ` +
        `${totals.sessions} sessions, ${totals.events} events`,
    );
  }

  /**
   * Midnight of the given instant in [DEFAULT_TIMEZONE], expressed as a UTC
   * Date — the same boundary the dashboard's `$dateToString` buckets on, so a
   * rolled-up day and a live-queried day cover exactly the same events.
   */
  private startOfDay(at: Date): Date {
    const key = this.toDateKey(at);
    // Vietnam is UTC+7 year-round (no DST), so local midnight is 17:00 UTC the
    // day before. Written as an explicit offset rather than a Date parse trick
    // because the server's own timezone must not decide this.
    return new Date(`${key}T00:00:00+07:00`);
  }

  private toDateKey(at: Date): string {
    return at.toLocaleDateString('en-CA', { timeZone: DEFAULT_TIMEZONE });
  }
}
