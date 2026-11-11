import { Injectable, Logger } from '@nestjs/common';
import { Cron } from '@nestjs/schedule';

import { NotificationDispatchService } from 'src/modules/notification/notification-dispatch.service';
import { NotificationTemplateService } from 'src/modules/notification/notification-template.service';
import {
  copyForLocale,
  variantsOf,
} from 'src/modules/notification/notification-variant.helper';
import {
  NotificationDeeplink,
  NotificationType,
} from 'src/modules/notification/notification.enum';
import { UserRepository } from 'src/modules/user/src/modules/auth/repository/user.repository';

import { CoachConfigService } from '../config/coach-config.service';
import { CoachPlanService } from '../plan/coach-plan.service';
import { CoachReminderDays } from '../plan/enum/plan.enum';
import { CoachPlanRepository } from '../plan/repository/coach-plan.repository';

/** ISO weekday (1 = Monday … 7 = Sunday) in a zone, via the same trick the dispatcher uses. */
function isoWeekdayIn(zone: string, now: Date): number | null {
  try {
    const label = new Intl.DateTimeFormat('en-US', {
      timeZone: zone,
      weekday: 'short',
    }).format(now);
    const order = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    const index = order.indexOf(label);

    return index === -1 ? null : index + 1;
  } catch {
    return null;
  }
}

/** Which of the three schedule shapes cover this weekday. */
function dayKindsFor(isoWeekday: number): CoachReminderDays[] {
  // CUSTOM and ONCE are always candidates here; whether THIS day is the
  // reader's pick is checked against the plan's own fields in `matchesDay`.
  const kinds: CoachReminderDays[] = [
    CoachReminderDays.DAILY,
    CoachReminderDays.CUSTOM,
    CoachReminderDays.ONCE,
  ];

  if (isoWeekday <= 5) kinds.push(CoachReminderDays.WEEKDAYS);
  else kinds.push(CoachReminderDays.WEEKENDS);

  return kinds;
}

/** Does this plan's schedule cover this weekday? "tự chọn" reads the reader's list. */
function matchesDay(
  reminder:
    | { days?: CoachReminderDays; customDays?: number[]; onceDate?: string | null }
    | undefined,
  isoWeekday: number,
  localDate: string | null,
): boolean {
  if (!reminder?.days) return false;
  if (reminder.days === CoachReminderDays.CUSTOM) {
    return (reminder.customDays ?? []).includes(isoWeekday);
  }
  // "Chỉ một lần": the reader's own calendar day, then never again — the date
  // simply stops matching, so nothing has to be disabled.
  if (reminder.days === CoachReminderDays.ONCE) {
    return Boolean(localDate) && reminder.onceDate === localDate;
  }

  return dayKindsFor(isoWeekday).includes(reminder.days);
}

/** The reader-local calendar day, YYYY-MM-DD, or null when the zone is bad. */
function localDateIn(timezone: string, now: Date): string | null {
  try {
    return new Intl.DateTimeFormat('en-CA', {
      timeZone: timezone,
      year: 'numeric',
      month: '2-digit',
      day: '2-digit',
    }).format(now);
  } catch {
    return null;
  }
}

/**
 * ④ — the commitment reminder, whose schedule belongs to the reader.
 *
 * This exists as its own dispatcher for one reason: every other notification in
 * the app fires at an hour the TEMPLATE owns, and this one fires at an hour the
 * READER picked when they made the promise. Everything downstream of "who, and
 * when" is shared — `NotificationDispatchService.sendDirect` owns the daily cap,
 * the atomic claim, the Firebase call and the log row, so none of that is
 * duplicated here.
 */
@Injectable()
export class CoachPlanReminderDispatcher {
  private readonly logger = new Logger(CoachPlanReminderDispatcher.name);

  private isRunning = false;

  constructor(
    private readonly planRepository: CoachPlanRepository,
    private readonly planService: CoachPlanService,
    private readonly configService: CoachConfigService,
    private readonly dispatchService: NotificationDispatchService,
    private readonly templateService: NotificationTemplateService,
    private readonly userRepository: UserRepository,
  ) {}

  @Cron('* * * * *')
  async dispatchDue() {
    if (this.isRunning) {
      this.logger.warn('Previous coach reminder tick still running, skipping');

      return;
    }

    this.isRunning = true;
    try {
      const sent = await this.run();
      if (sent > 0) this.logger.log(`Coach plan reminders sent: ${sent}`);
    } catch (error: any) {
      this.logger.error(`Coach reminder tick failed: ${error?.message}`);
    } finally {
      this.isRunning = false;
    }
  }

  async run(now = new Date()): Promise<number> {
    if (!(await this.configService.isEnabled())) return 0;

    // Zero database work on a tick where nobody has a reminder armed, which is
    // most of them.
    const times = await this.planRepository.distinctArmedReminderTimes();
    if (!times.length) return 0;

    const template = (await this.templateService.findAll()).find(
      (t) => t.type === NotificationType.COACH_PLAN_REMINDER,
    );
    if (!template?.enabled) return 0;

    let sent = 0;

    for (const { hour, minute } of times) {
      sent += await this.dispatchTime(template, hour, minute ?? 0, now);
    }

    return sent;
  }

  private async dispatchTime(
    template: Awaited<
      ReturnType<NotificationTemplateService['findAll']>
    >[number],
    hour: number,
    minute: number,
    now: Date,
  ): Promise<number> {
    const zones = await this.dispatchService.zonesDueAt(hour, minute, now);
    if (!zones.length) return 0;

    const candidates = await this.userRepository.findPushCandidatesByTimezones(
      zones,
    );
    if (!candidates.length) return 0;

    const byId = new Map(
      candidates.map((c: { _id: unknown }) => [String(c._id), c]),
    );

    // Every day-kind at once, then filtered per reader: two readers due at the
    // same local hour can be on different weekdays, so "is it a weekday" is a
    // question about their zone rather than about the tick.
    const plans = await this.planRepository.findDueReminders({
      userIds: Array.from(byId.keys()),
      hour,
      minute,
      dayKinds: [
        CoachReminderDays.DAILY,
        CoachReminderDays.WEEKDAYS,
        CoachReminderDays.WEEKENDS,
        CoachReminderDays.CUSTOM,
        CoachReminderDays.ONCE,
      ],
    });
    if (!plans.length) return 0;

    /**
     * One push per reader, however many commitments share the hour.
     *
     * The oldest wins — it is the one that has been waiting longest to be
     * asked about. The rest are simply not sent rather than queued for later:
     * a reminder that arrives a day late is about a moment that has passed.
     */
    const firstPerUser = new Map<string, (typeof plans)[number]>();
    for (const plan of plans) {
      const candidate = byId.get(plan.userId) as
        | { timezone?: string; language?: string; devices?: unknown[] }
        | undefined;
      if (!candidate?.timezone) continue;

      const weekday = isoWeekdayIn(candidate.timezone, now);
      if (!weekday) continue;
      if (
        !matchesDay(plan.reminder, weekday, localDateIn(candidate.timezone, now))
      ) {
        continue;
      }

      if (!firstPerUser.has(plan.userId)) firstPerUser.set(plan.userId, plan);
    }

    let sent = 0;
    const notified: string[] = [];

    for (const [userId, plan] of firstPerUser) {
      const candidate = byId.get(userId) as any;

      const copy = copyForLocale(
        variantsOf(template)[0]?.copies,
        candidate?.language,
      );
      if (!copy) continue;

      // The reader's own words go in verbatim. The frame around them is the
      // only translated part — which is the whole design of this notification.
      const variables = { context: plan.context, action: plan.action };

      try {
        const didSend = await this.dispatchService.sendDirect({
          candidate,
          type: NotificationType.COACH_PLAN_REMINDER,
          deeplink: NotificationDeeplink.COACH,
          title: this.render(copy.title, variables),
          body: this.render(copy.body, variables),
          payload: { planId: String(plan._id) },
          meta: { planId: String(plan._id) },
          now,
        });

        if (didSend) {
          sent += 1;
          notified.push(String(plan._id));
        }
      } catch (error: any) {
        this.logger.warn(
          `Coach reminder failed for user=${userId}: ${error?.message}`,
        );
      }
    }

    await this.planService.markNotified(notified);

    return sent;
  }

  /** `{context}` / `{action}`, the same brace syntax every other template uses. */
  private render(text: string, variables: Record<string, string>): string {
    return text.replace(/\{(\w+)\}/g, (match, key: string) =>
      variables[key] !== undefined ? variables[key] : match,
    );
  }
}
