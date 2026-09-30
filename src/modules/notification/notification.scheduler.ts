import { Injectable, Logger } from '@nestjs/common';
import { Cron } from '@nestjs/schedule';

import { INotificationSchedulerStatus } from './interface/notification-scheduler-status.interface';
import { NotificationCampaignService } from './notification-campaign.service';
import { NotificationDispatchService } from './notification-dispatch.service';

@Injectable()
export class NotificationScheduler {
  private readonly logger = new Logger(NotificationScheduler.name);

  /** Guards against a tick starting while the previous one is still walking users. */
  private isRunning = false;

  /**
   * Observability for the tick itself, exposed by
   * `GET /notifications/scheduler-status`.
   *
   * Kept in memory on purpose: this answers "is the cron alive in THIS process",
   * which is exactly the question a database row cannot answer — a tick that
   * never fires, or one that throws before reaching the users query, writes
   * nothing to Mongo and is invisible unless you can read the container log.
   * Resets on restart, which is correct: a fresh process has ticked zero times.
   */
  private startedAt = new Date();
  private tickCount = 0;
  private lastTickAt: Date | null = null;
  private lastDueAt: Date | null = null;
  private lastSentAt: Date | null = null;
  private lastResults: Record<string, number> | null = null;
  private lastError: string | null = null;
  private lastErrorAt: Date | null = null;

  constructor(
    private readonly dispatchService: NotificationDispatchService,
    private readonly campaignService: NotificationCampaignService,
  ) {}

  /**
   * Every minute — NOT one cron per notification.
   *
   * Send times are local and now carry a minute (`localHour` + `localMinute`), so
   * a template set to 14:37 has to be able to fire at :37. It was a quarter-hour
   * cron while the schedule was hour-only.
   *
   * One job still covers the whole planet: the world holds ~38 distinct UTC
   * offsets including the :30 and :45 ones (India, Nepal, Chatham), and each tick
   * asks "which zones have just reached this template's local time". A tick where
   * nothing is due costs one `Intl` read per zone and no database work at all
   * (see `NotificationDispatchService.zoneClocks`).
   */
  @Cron('* * * * *')
  async dispatchDue() {
    if (this.isRunning) {
      this.logger.warn('Previous notification tick still running, skipping');
      return;
    }
    this.isRunning = true;
    this.tickCount += 1;
    this.lastTickAt = new Date();
    try {
      const results = await this.dispatchService.dispatchDueNotifications();
      this.lastResults = results;
      // `results` carries a key per template that had at least one zone due, so
      // its emptiness distinguishes "nothing was scheduled for now" from
      // "something was due but nobody received it".
      if (Object.keys(results).length > 0) this.lastDueAt = new Date();
      const total = Object.values(results).reduce((sum, n) => sum + n, 0);
      if (total > 0) {
        this.lastSentAt = new Date();
        this.logger.log(`Notifications sent: ${JSON.stringify(results)}`);
      }
    } catch (error: any) {
      this.lastError = error?.message ?? String(error);
      this.lastErrorAt = new Date();
      this.logger.error(`Notification tick failed: ${error?.message}`);
    }

    // Manual campaigns ride the same tick, in their own try: a campaign that
    // throws must not stop the five scheduled types from being dispatched — and
    // it already keeps its own error on the campaign document, so this only
    // guards the tick.
    try {
      const campaign = await this.campaignService.runDueCampaigns();
      if (campaign.sent > 0) {
        this.lastSentAt = new Date();
        this.logger.log(`Campaign notifications sent: ${campaign.sent}`);
      }
    } catch (error: any) {
      this.logger.error(`Campaign tick failed: ${error?.message}`);
    } finally {
      this.isRunning = false;
    }
  }

  /**
   * What the tick has actually been doing, for the admin's delivery monitor.
   *
   * Read the three timestamps together — they separate the failure modes that
   * otherwise all look like "no notification arrived":
   * - `lastTickAt` null → the cron never fired in this process at all.
   * - `lastTickAt` fresh but `lastDueAt` null → the cron runs and no template's
   *   local send time has come round yet (or no zone matched one).
   * - `lastDueAt` set but `lastSentAt` null → something was due and every
   *   candidate was filtered out or failed; `notification_logs` has the reason
   *   per user.
   * - `lastError` set → the tick threw; the message is the whole answer.
   */
  getStatus(): INotificationSchedulerStatus {
    return {
      startedAt: this.startedAt,
      now: new Date(),
      isRunning: this.isRunning,
      tickCount: this.tickCount,
      lastTickAt: this.lastTickAt,
      lastDueAt: this.lastDueAt,
      lastSentAt: this.lastSentAt,
      lastResults: this.lastResults,
      lastError: this.lastError,
      lastErrorAt: this.lastErrorAt,
    };
  }
}
