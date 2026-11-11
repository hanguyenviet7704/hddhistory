import { Injectable, Logger } from '@nestjs/common';
import { Cron } from '@nestjs/schedule';

import { CourseRepository } from 'src/modules/courses/src/modules/course/repository/course.repository';
import { NotificationDispatchService } from 'src/modules/notification/notification-dispatch.service';
import { NotificationTemplateService } from 'src/modules/notification/notification-template.service';
import {
  pickVariant,
  variantsOf,
} from 'src/modules/notification/notification-variant.helper';
import { NotificationType } from 'src/modules/notification/notification.enum';
import { SegmentMemberFilterService } from 'src/modules/segment/segment-member-filter.service';
import { UserRepository } from 'src/modules/user/src/modules/auth/repository/user.repository';

import { OnboardingAnswerRepository } from './repository/onboarding-answer.repository';

const TIME_REGEX = /^(\d{2}):(\d{2})$/;

/** One candidate user, projected down to what a send needs — same shape as
 * `NotificationDispatchService`'s own `PushCandidate`. */
interface StudyReminderCandidate {
  _id: unknown;
  name?: string;
  language?: string;
  timezone?: string;
  devices?: { pushToken?: string; pushEnabled?: boolean }[];
}

/**
 * Nhắc học theo giờ USER chọn ở onboarding — sao y `CoachPlanReminderDispatcher`:
 * mọi thứ sau "ai, lúc nào" (trần/ngày, claim, FCM, log) là của
 * `NotificationDispatchService.sendDirect`. Ở đây chỉ: giờ nào đang có người
 * đặt → zone nào vừa tới giờ đó → user nào trong zone có đúng giờ đó (+ segment
 * của template) → chọn biến thể → gửi.
 *
 * Một push mỗi user mỗi tick tự nhiên xảy ra: `studyReminderTime` là MỘT giá trị
 * trên user, nên user chỉ khớp đúng một `time` trong vòng lặp — không cần gom
 * "first per user" như Coach (nơi nhiều commitment có thể trùng giờ).
 */
@Injectable()
export class OnboardingStudyReminderDispatcher {
  private readonly logger = new Logger(OnboardingStudyReminderDispatcher.name);
  private isRunning = false;

  constructor(
    private readonly dispatchService: NotificationDispatchService,
    private readonly templateService: NotificationTemplateService,
    private readonly userRepository: UserRepository,
    private readonly answerRepository: OnboardingAnswerRepository,
    private readonly courseRepository: CourseRepository,
    private readonly segmentFilterService: SegmentMemberFilterService,
  ) {}

  @Cron('* * * * *')
  async dispatchDue() {
    if (this.isRunning) {
      this.logger.warn('Previous study reminder tick still running, skipping');
      return;
    }
    this.isRunning = true;
    try {
      const sent = await this.run();
      if (sent > 0) this.logger.log(`Onboarding study reminders sent: ${sent}`);
    } catch (error: any) {
      this.logger.error(`Study reminder tick failed: ${error?.message}`);
    } finally {
      this.isRunning = false;
    }
  }

  async run(now = new Date()): Promise<number> {
    // Zero database work on a tick where nobody has a reminder time armed,
    // which is most of them.
    const times = await this.userRepository.distinctStudyReminderTimes();
    if (!times.length) return 0;

    const template = (await this.templateService.findAll()).find(
      t => t.type === NotificationType.ONBOARDING_STUDY_REMINDER,
    );
    if (!template?.enabled) return 0;

    const segmentFilter =
      await this.segmentFilterService.memberFilterForSegments(
        template.segmentIds,
      );

    let sent = 0;
    for (const time of times) {
      const match = TIME_REGEX.exec(time);
      if (!match) continue;
      sent += await this.dispatchTime(
        template,
        time,
        Number(match[1]),
        Number(match[2]),
        segmentFilter,
        now,
      );
    }
    return sent;
  }

  private async dispatchTime(
    template: Awaited<
      ReturnType<NotificationTemplateService['findAll']>
    >[number],
    time: string,
    hour: number,
    minute: number,
    segmentFilter: Awaited<
      ReturnType<SegmentMemberFilterService['memberFilterForSegments']>
    >,
    now: Date,
  ): Promise<number> {
    const zones = await this.dispatchService.zonesDueAt(hour, minute, now);
    if (!zones.length) return 0;

    // Segment targeting pushed INTO the candidate query, same convention as
    // `NotificationDispatchService.dispatchTemplate` — filtering afterward would
    // spend the query's cap on people the admin excluded.
    const candidates = (await this.userRepository.findPushCandidatesByTimezones(
      zones,
      undefined,
      {
        studyReminderTime: time,
        ...(segmentFilter ?? {}),
      } as any,
    )) as unknown as StudyReminderCandidate[];
    if (!candidates.length) return 0;

    // {course_name}: khoá đã chọn ở S10, không có thì khoá gợi ý đầu.
    const answers = await this.answerRepository.findByUserIds(
      candidates.map(c => String(c._id)),
    );
    const courseIdOf = new Map(
      answers.map(a => [
        a.userId,
        a.chosenCourseId ?? a.recommendedCourseIds?.[0] ?? null,
      ]),
    );
    const courseIds = [
      ...new Set(
        [...courseIdOf.values()].filter((id): id is string => Boolean(id)),
      ),
    ];
    const courses = courseIds.length
      ? await this.courseRepository.findBriefByIds(courseIds)
      : [];
    const titleOf = new Map(
      courses.map((c: any) => [String(c._id), c.title ?? {}]),
    );

    const variants = variantsOf(template);
    let sent = 0;
    for (const candidate of candidates) {
      const userId = String(candidate._id);
      const lang = (candidate.language ?? 'en').toLowerCase().split(/[-_]/)[0];
      const courseTitle: any = titleOf.get(courseIdOf.get(userId) ?? '');
      const variables: Record<string, string> = {
        user_name: (candidate.name ?? '').trim(),
        course_name:
          courseTitle?.[lang] ?? courseTitle?.en ?? courseTitle?.vi ?? '',
      };
      const pick = pickVariant({
        variants,
        language: candidate.language,
        variables,
      });
      if (!pick) continue;

      try {
        const didSend = await this.dispatchService.sendDirect({
          candidate,
          type: NotificationType.ONBOARDING_STUDY_REMINDER,
          deeplink: template.deeplink,
          title: this.render(pick.copy.title, variables),
          body: this.render(pick.copy.body, variables),
          imageUrl: template.imageUrl,
          meta: { variantKey: pick.variant.key, reminderTime: time },
          now,
        });
        if (didSend) sent += 1;
      } catch (error: any) {
        this.logger.warn(
          `Study reminder failed for user=${userId}: ${error?.message}`,
        );
      }
    }
    return sent;
  }

  /** Same brace syntax every scheduled template uses. */
  private render(template: string, variables: Record<string, string>): string {
    if (!template) return '';
    return template.replace(/\{(\w+)\}/g, (match, key: string) =>
      variables[key] !== undefined ? variables[key] : match,
    );
  }
}
