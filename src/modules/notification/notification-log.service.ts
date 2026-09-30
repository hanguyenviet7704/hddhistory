import { Injectable } from '@nestjs/common';

import { DEFAULT_APP_ENV } from 'src/modules/analytics/constant/dashboard.constant';
import { UserEventRepository } from 'src/modules/analytics/repository/user-event.repository';

import {
  NOTI_TAP_EVENT,
  NOTI_TAP_TYPE_PARAM,
} from './constant/noti-tap.constant';
import {
  GetNotificationLogDto,
  GetNotificationSummaryDto,
} from './dto/notification-log.dto';
import { NotificationLogStatus, NotificationType } from './notification.enum';
import { NotificationLogRepository } from './repository/notification-log.repository';

@Injectable()
export class NotificationLogService {
  constructor(
    private readonly logRepository: NotificationLogRepository,
    private readonly userEventRepository: UserEventRepository,
  ) {}

  async findAll(dto: GetNotificationLogDto) {
    return this.logRepository.findOption(dto);
  }

  /**
   * Counts per type × status for the admin dashboard, plus how many taps each
   * type got. Defaults to the last 7 local days, which is the window an
   * operator actually looks at.
   *
   * ## What the click number is, and what it is not
   *
   * Sends come from this API's own `notification_logs`; clicks come from the
   * app's `noti_tap` events in `user_events`. Two different collections written
   * by two different systems, joined only by the notification TYPE — so the
   * count is honest about a window and vague about a single day:
   *
   * - A tap is counted in the window it HAPPENED, not the window its push was
   *   sent in. Someone who gets the 21:00 push and taps it at 08:00 the next
   *   morning counts against the next day. Attributing a tap to its own send
   *   would need a send id in the push payload and the app echoing it back,
   *   which is an app release, not a query.
   * - The two sides are not even on the same time axis: a log row is bucketed by
   *   the USER's local calendar day, an event by its `clientTs` instant. The
   *   window is converted to UTC bounds below, which is right in the middle and
   *   wrong at both edges by up to a day.
   * - `noti_tap` only exists in app builds from 2026-08-08 on, and `user_events`
   *   self-destructs after 90 days. Older readers are invisible and older
   *   windows are empty, in both cases with a full send count beside them — so a
   *   low number can mean "nobody tapped" or "nobody could report".
   *
   * Over a week these wash out. Over one day, read it as a direction.
   */
  async summary(dto: GetNotificationSummaryDto) {
    const toDate = dto.toDate ?? this.today();
    const fromDate = dto.fromDate ?? this.daysBefore(toDate, 6);
    const appEnv = dto.appEnv ?? DEFAULT_APP_ENV;

    const [rows, clicksByType] = await Promise.all([
      this.logRepository.summaryByType(fromDate, toDate),
      this.userEventRepository.countEventsByParam({
        name: NOTI_TAP_EVENT,
        paramKey: NOTI_TAP_TYPE_PARAM,
        appEnv,
        // Whole days, inclusive at both ends, matching how `fromDate`/`toDate`
        // read on the screen.
        from: new Date(`${fromDate}T00:00:00.000Z`),
        to: new Date(`${toDate}T23:59:59.999Z`),
      }),
    ]);

    const byType: Record<string, Record<string, number>> = {};
    for (const type of Object.values(NotificationType)) {
      byType[type] = {
        [NotificationLogStatus.SENT]: 0,
        [NotificationLogStatus.FAILED]: 0,
        [NotificationLogStatus.SKIPPED]: 0,
        clicks: clicksByType[type] ?? 0,
      };
    }

    for (const row of rows) {
      const bucket = byType[row._id.type];
      if (!bucket) continue;
      bucket[row._id.status] = row.count;
    }

    return { fromDate, toDate, appEnv, byType };
  }

  private today() {
    return new Date().toISOString().slice(0, 10);
  }

  private daysBefore(date: string, days: number) {
    const base = new Date(`${date}T00:00:00.000Z`);
    base.setUTCDate(base.getUTCDate() - days);
    return base.toISOString().slice(0, 10);
  }
}
