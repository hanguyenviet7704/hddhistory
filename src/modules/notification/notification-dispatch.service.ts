import { Injectable, Logger, NotFoundException } from '@nestjs/common';

import { FirebaseService } from '@base/config/firebase';
import { CourseRepository } from 'src/modules/courses/src/modules/course/repository/course.repository';
import { UserProgressRepository } from 'src/modules/courses/src/modules/progress/src/modules/user-progress/repository/user-progress.repository';
import { WeekRecapRepository } from 'src/modules/courses/src/modules/progress/src/modules/week-recap/repository/week-recap.repository';
import { QuoteRepository } from 'src/modules/courses/src/modules/quotes/repository/quote.repository';
import { SkillsetRepository } from 'src/modules/courses/src/modules/skillset/repository/skillset.repository';
import { UserHabitState } from 'src/modules/habit/src/modules/user-habit/enum/user-habit.enum';
import { HabitCheckinRepository } from 'src/modules/habit/src/modules/user-habit/repository/habit-checkin.repository';
import { UserHabitRepository } from 'src/modules/habit/src/modules/user-habit/repository/user-habit.repository';
import { UserRepository } from 'src/modules/user/src/modules/auth/repository/user.repository';

import { describeSendFailure } from './notification-failure.helper';
import { NotificationTemplateService } from './notification-template.service';
import {
  groupStoredZonesByCanonical,
  storedZonesForCanonical,
} from './notification-timezone.helper';
import {
  copyForLocale,
  INotificationVariantPick,
  pickVariant,
  shiftLocalDate,
  variantCooldownMap,
  variantsOf,
  VARIANT_COOLDOWN_DAYS,
} from './notification-variant.helper';
import { MAX_NOTIFICATIONS_PER_DAY } from './notification.defaults';
import {
  NotificationDeeplink,
  NotificationLogStatus,
  NotificationType,
} from './notification.enum';
import { SegmentMemberFilterService } from '../segment/segment-member-filter.service';
import { NotificationLogRepository } from './repository/notification-log.repository';
import { NotificationTemplate } from './schema/notification-template.schema';

/** One candidate user, projected down to what a send needs. */
interface PushCandidate {
  _id: any;
  name?: string;
  language?: string;
  timezone?: string;
  devices?: { pushToken?: string; pushEnabled?: boolean }[];
}

/**
 * What a type needs that is the same for every reader on this tick.
 *
 * Resolved once per template rather than per candidate: the newest course is one
 * document for the whole planet, so reading it inside the user loop would turn a
 * single query into one per user. Translations stay raw here because the locale
 * is only known per user.
 */
interface SharedContext {
  newCourse?: {
    courseId: string;
    /** ITranslation maps, resolved per user in [pickTranslation]. */
    title: unknown;
    topicTitle: unknown;
  };
}

@Injectable()
export class NotificationDispatchService {
  private readonly logger = new Logger(NotificationDispatchService.name);

  /** See [storedZonesByCanonical] — long enough to spare a `distinct` per tick,
   * short enough that a newly-seen zone joins well inside the send window. */
  private static readonly STORED_ZONE_TTL_MS = 5 * 60 * 1000;

  private storedZoneCache: {
    data: Map<string, string[]>;
    expiresAt: number;
  } | null = null;

  /**
   * Skillset titles behind `{topic_name}`, briefly cached.
   *
   * The unfinished-lesson nudge needs the title of whatever course THAT reader
   * stopped in, so unlike the newest course it cannot be hoisted out of the user
   * loop. Titles change far less often than a tick runs, and there are only as
   * many as there are skillsets, so a short cache removes the per-user read
   * without holding anything meaningful stale.
   */
  private static readonly SKILLSET_TITLE_TTL_MS = 5 * 60 * 1000;

  private skillsetTitleCache = new Map<
    string,
    { title: unknown; expiresAt: number }
  >();

  constructor(
    private readonly userRepository: UserRepository,
    private readonly userProgressRepository: UserProgressRepository,
    private readonly courseRepository: CourseRepository,
    private readonly skillsetRepository: SkillsetRepository,
    private readonly userHabitRepository: UserHabitRepository,
    private readonly habitCheckinRepository: HabitCheckinRepository,
    private readonly quoteRepository: QuoteRepository,
    private readonly logRepository: NotificationLogRepository,
    private readonly templateService: NotificationTemplateService,
    private readonly firebaseService: FirebaseService,
    // The snapshot store only — never WeekRecapService, which reads the
    // request-scoped RequestService and would drag this singleton (and the
    // @Cron above it) into request scope, the trap notification-campaign
    // already documents.
    private readonly weekRecapRepository: WeekRecapRepository,
    // The filter compiler, NOT SegmentService: that one is request-scoped and
    // would drag this singleton (and the @Cron above it) into request scope.
    private readonly segmentService: SegmentMemberFilterService,
  ) {}

  /**
   * Runs every enabled type whose local send time has just passed somewhere on
   * earth. Called by the scheduler once a minute.
   */
  async dispatchDueNotifications(now = new Date()) {
    const templates = await this.templateService.findEnabled();
    const results: Record<string, number> = {};

    // Read every zone's clock ONCE per tick and let all templates share it.
    // `timezonesAtLocalHour` used to re-enumerate ~400 zones and build an
    // `Intl.DateTimeFormat` for each, per template — affordable every quarter
    // hour, wasteful every minute.
    const clocks = this.zoneClocks(now);

    // Which spellings of a zone users actually have. ICU enumerates
    // `Asia/Saigon` while phones store `Asia/Ho_Chi_Minh`, so a due zone has to
    // be translated back into the stored form or the query matches nobody — see
    // `notification-timezone.helper.ts` for why this was worth its own module.
    const storedByCanonical = await this.storedZonesByCanonical();

    for (const template of templates) {
      // The Coach reminder and the onboarding study reminder are both scheduled
      // per READER, not per template: the reader picks the hour (a commitment's
      // hour, or `users.studyReminderTime`), so `template.localHour` means
      // nothing for either. Their template rows exist only to carry the five
      // locales of the copy and the deeplink; the schedule halves live in
      // `CoachPlanReminderDispatcher` / `OnboardingStudyReminderDispatcher`,
      // which call `sendDirect` below.
      if (
        template.type === NotificationType.COACH_PLAN_REMINDER ||
        template.type === NotificationType.ONBOARDING_STUDY_REMINDER
      ) {
        continue;
      }

      let dueCanonical = this.timezonesDueAt(
        template.localHour,
        template.localMinute ?? 0,
        clocks,
      );
      // A weekly template (the weekly-recap pair) only fires on its own local
      // weekday — evaluated per ZONE, like the hour: Monday 10:00 in Hanoi is
      // still Sunday in Los Angeles, and each side gets its own Monday.
      if (template.localWeekday) {
        dueCanonical = dueCanonical.filter(
          zone => this.localWeekdayIso(now, zone) === template.localWeekday,
        );
      }
      if (dueCanonical.length === 0) continue;

      const zones = storedZonesForCanonical(dueCanonical, storedByCanonical);
      results[template.type] = await this.dispatchTemplate(
        template as NotificationTemplate,
        zones,
        now,
      );
    }

    return results;
  }

  /**
   * Stored zone spellings grouped by canonical name, cached briefly.
   *
   * The set only changes when a user registers a device from a zone nobody has
   * used before, so re-reading it every minute would be a `distinct` per tick
   * for a value that barely moves. A stale minute costs nothing: the send window
   * is 15 minutes wide, so a zone that appears mid-cache is still caught.
   */
  /**
   * Stored zone spellings whose local clock has just reached `hour:minute`.
   *
   * Public because manual campaigns send at each reader's own local hour too —
   * the same contract, so it must be the same computation (send window, the
   * Asia/Saigon vs Asia/Ho_Chi_Minh spelling problem, the cached zone list).
   * A second implementation would drift from this one the first time either
   * changed.
   *
   * [onLocalDate] (`YYYY-MM-DD`) narrows it to zones where that is the local day
   * the send time belongs to — what a one-off campaign needs and a standing
   * template does not, since a template is meant to come round every day.
   */
  async zonesDueAt(
    hour: number,
    minute: number,
    now = new Date(),
    onLocalDate?: string,
  ) {
    let dueCanonical = this.timezonesDueAt(hour, minute, this.zoneClocks(now));
    // [onLocalDate] is what makes a one-off send happen on ONE day. The clock
    // test alone only knows "it is 20:00 somewhere", which is true again every
    // 24 hours — the same shape of filter `localWeekday` applies for the weekly
    // template pair, and for the same reason.
    if (onLocalDate) {
      dueCanonical = dueCanonical.filter(
        zone => this.localDateAtSendTime(now, zone, hour, minute) === onLocalDate,
      );
    }
    if (dueCanonical.length === 0) return [];
    return storedZonesForCanonical(
      dueCanonical,
      await this.storedZonesByCanonical(),
    );
  }

  /**
   * The local date of the moment `hour:minute` actually came round in [zone] —
   * not the local date right now.
   *
   * They differ inside the catch-up window whenever the send time sits just
   * before local midnight: a 23:58 send picked up when the zone already reads
   * 00:05 belongs to the day that has just ended, and comparing against today
   * would drop precisely the readers the window exists to rescue.
   */
  private localDateAtSendTime(
    now: Date,
    zone: string,
    hour: number,
    minute: number,
  ): string {
    const elapsed =
      (this.localMinutesOfDay(now, zone) - (hour * 60 + minute) + 1440) % 1440;
    return this.localDate(new Date(now.getTime() - elapsed * 60_000), zone);
  }

  private async storedZonesByCanonical(): Promise<Map<string, string[]>> {
    const now = Date.now();
    if (this.storedZoneCache && this.storedZoneCache.expiresAt > now) {
      return this.storedZoneCache.data;
    }

    const stored = await this.userRepository.distinctPushCandidateTimezones();
    const data = groupStoredZonesByCanonical(stored);
    this.storedZoneCache = {
      data,
      expiresAt: now + NotificationDispatchService.STORED_ZONE_TTL_MS,
    };
    return data;
  }

  private async dispatchTemplate(
    template: NotificationTemplate,
    timezones: string[],
    now: Date,
  ) {
    // Null means the type has nothing to say to anybody right now, so the
    // candidate query is not worth running.
    const shared = await this.resolveSharedContext(
      template.type,
      template.deeplink,
    );
    if (!shared) return 0;

    // Segment targeting is pushed INTO the candidate query, not applied to its
    // result: the query is capped (default 5000 rows), so filtering afterwards
    // would spend that cap on people the admin excluded and could return none
    // of the targeted ones on a busy zone group.
    //
    // A template whose segments have all been deleted sends to nobody rather
    // than to everybody — see `memberFilterForSegments`.
    const segmentFilter = await this.segmentService.memberFilterForSegments(
      template.segmentIds,
    );

    const candidates = (await this.userRepository.findPushCandidatesByTimezones(
      timezones,
      undefined,
      segmentFilter ?? undefined,
    )) as unknown as PushCandidate[];

    let sent = 0;
    for (const candidate of candidates) {
      try {
        const didSend = await this.dispatchToUser(
          template,
          candidate,
          now,
          shared,
        );
        if (didSend) sent += 1;
      } catch (error: any) {
        // One user's failure must never abort the tick for everybody else.
        this.logger.error(
          `[${template.type}] user ${String(candidate._id)} failed: ${error?.message}`,
        );
      }
    }
    return sent;
  }

  private async dispatchToUser(
    template: NotificationTemplate,
    candidate: PushCandidate,
    now: Date,
    shared: SharedContext,
  ): Promise<boolean> {
    const userId = String(candidate._id);
    const localDate = this.localDate(now, candidate.timezone);

    // One read covers both the daily rules (today's rows) and the variant
    // cooldown (the days before it).
    const history = await this.logRepository.findByUserAndDateRange(
      userId,
      shiftLocalDate(localDate, -VARIANT_COOLDOWN_DAYS),
      localDate,
    );
    const dayLog = history.filter(row => row.localDate === localDate);
    // Once per type per day.
    if (dayLog.some(row => row.type === template.type)) return false;

    // The only cross-type rule left is the daily cap. Habit tracking used to be
    // suppressed on any day that had already carried the unfinished-lesson
    // nudge; that is gone on purpose. The two ask for different things — come
    // back to a lesson, and tick today's habit — and a habit left unchecked is
    // not answered by finishing a lesson, so silencing one for the other simply
    // lost a reminder the reader still needed.
    const alreadySent = dayLog.filter(
      row => row.status === NotificationLogStatus.SENT,
    );
    if (alreadySent.length >= MAX_NOTIFICATIONS_PER_DAY) return false;

    const tokens = (candidate.devices ?? [])
      .filter(device => device.pushEnabled !== false && !!device.pushToken)
      .map(device => device.pushToken as string);
    if (tokens.length === 0) return false;

    const context = await this.resolveContext(
      template.type,
      userId,
      candidate,
      shared,
    );
    if (!context) return false;

    // After the context, not before: which wordings can be sent depends on what
    // the context could actually fill in, so a variant asking for
    // `{topic_name}` is dropped rather than pushed with the placeholder showing.
    const pick = pickVariant({
      variants: variantsOf(template),
      language: candidate.language,
      variables: context.variables,
      daysSinceLastUse: variantCooldownMap(
        history.filter(row => row.type === template.type),
        localDate,
      ),
    });
    if (!pick) return false;

    // Claim before sending: the unique (user, type, day) index is what makes two
    // workers on the same tick unable to double-send.
    const claimed = await this.logRepository.claimSlot(
      userId,
      template.type,
      localDate,
    );
    if (!claimed) return false;

    const title = this.render(pick.copy.title, context.variables);
    const body = this.render(pick.copy.body, context.variables);

    const result = await this.firebaseService.sendToTokens(
      tokens,
      title,
      body,
      this.withDestinationPayload(template.deeplink, shared, {
        type: template.type,
        deeplink: template.deeplink,
        ...context.payload,
      }),
      // One image per template, shared by every variant — the artwork belongs to
      // the notification type, not to the wording that happened to be picked.
      template.imageUrl,
    );

    if (result.deadTokens.length > 0) {
      await this.userRepository.pruneDeadPushTokens(result.deadTokens);
    }

    const status =
      result.successCount > 0
        ? NotificationLogStatus.SENT
        : NotificationLogStatus.FAILED;

    await this.logRepository.completeSlot(userId, template.type, localDate, {
      status,
      sentAt: new Date(),
      locale: candidate.language,
      title,
      body,
      deeplink: template.deeplink,
      deviceCount: tokens.length,
      successCount: result.successCount,
      failureCount: result.failureCount,
      reason:
        status === NotificationLogStatus.FAILED
          ? describeSendFailure(result.failures)
          : undefined,
      // `variantKey` is what the cooldown reads back on later days. It is written
      // on a failed row too — not for the cooldown, which only counts sends, but
      // because the row is the admin's answer to "which wording did this go out
      // as", and that question outlives the delivery result.
      meta: { ...context.meta, variantKey: pick.variant.key },
    });

    return status === NotificationLogStatus.SENT;
  }

  /**
   * Everything a type needs that does not vary by reader, or null when the type
   * cannot send to anybody on this tick.
   *
   * Only the new-course announcement has such data. The daily quote is
   * deliberately left per-user — two readers on the same tick are meant to get
   * different quotes, so hoisting that read would change the product.
   */
  /**
   * Send one notification whose SCHEDULE is somebody else's business.
   *
   * Everything after "who, and when" is identical for every push this app makes
   * — the daily cap, the atomic claim that makes a double-send impossible, the
   * Firebase call, dead-token pruning, the log row that answers "what went out"
   * a week later. This is that everything, exposed once, so a feature with its
   * own timing (④, whose hour the reader chooses per commitment) does not have
   * to reimplement any of it and drift.
   *
   * The caller owns the copy: it already resolved the reader's language and
   * filled the frame with their words, which this has no way to do.
   */
  async sendDirect(params: {
    candidate: {
      _id: any;
      language?: string;
      timezone?: string;
      devices?: { pushToken?: string; pushEnabled?: boolean }[];
    };
    type: NotificationType;
    deeplink: NotificationDeeplink;
    title: string;
    body: string;
    /**
     * Optional artwork, on the same terms as the copy: this path has no template
     * to read one off, so a caller that wants an image passes its own URL.
     */
    imageUrl?: string | null;
    payload?: Record<string, string>;
    meta?: Record<string, unknown>;
    now?: Date;
  }): Promise<boolean> {
    const { candidate, type, deeplink, title, body, imageUrl, payload, meta } =
      params;
    const now = params.now ?? new Date();

    const userId = String(candidate._id);
    const localDate = this.localDate(now, candidate.timezone);

    const dayLog = (
      await this.logRepository.findByUserAndDateRange(
        userId,
        localDate,
        localDate,
      )
    ).filter(row => row.localDate === localDate);

    // Once per type per day, and never past the whole-app daily cap: a
    // commitment reminder is not exempt from the ceiling that stops HDDhistory
    // becoming noise.
    if (dayLog.some(row => row.type === type)) return false;

    const alreadySent = dayLog.filter(
      row => row.status === NotificationLogStatus.SENT,
    );
    if (alreadySent.length >= MAX_NOTIFICATIONS_PER_DAY) return false;

    const tokens = (candidate.devices ?? [])
      .filter(device => device.pushEnabled !== false && !!device.pushToken)
      .map(device => device.pushToken as string);
    if (tokens.length === 0) return false;

    const claimed = await this.logRepository.claimSlot(userId, type, localDate);
    if (!claimed) return false;

    const result = await this.firebaseService.sendToTokens(
      tokens,
      title,
      body,
      {
        type,
        deeplink,
        ...(payload ?? {}),
      },
      imageUrl,
    );

    if (result.deadTokens.length > 0) {
      await this.userRepository.pruneDeadPushTokens(result.deadTokens);
    }

    const status =
      result.successCount > 0
        ? NotificationLogStatus.SENT
        : NotificationLogStatus.FAILED;

    await this.logRepository.completeSlot(userId, type, localDate, {
      status,
      sentAt: new Date(),
      locale: candidate.language,
      title,
      body,
      deeplink,
      deviceCount: tokens.length,
      successCount: result.successCount,
      failureCount: result.failureCount,
      reason:
        status === NotificationLogStatus.FAILED
          ? describeSendFailure(result.failures)
          : undefined,
      meta,
    });

    return status === NotificationLogStatus.SENT;
  }

  /**
   * Fills in what the DESTINATION needs but the TYPE's own context did not
   * supply — today that is `new_course` wanting a `courseId`.
   *
   * Kept apart from [resolveContext] because the two answer different
   * questions: that one collects what the WORDING has to render, this one what
   * the TAP has to land. Only `new_course` announces the course it is about, so
   * only `new_course` fills the id from its own context; every other template
   * pointed at that destination gets the newest published course, which is what
   * the destination means.
   */
  private withDestinationPayload(
    deeplink: string,
    shared: SharedContext,
    payload: Record<string, string>,
  ): Record<string, string> {
    if (deeplink !== NotificationDeeplink.NEW_COURSE) return payload;
    if (payload.courseId || !shared.newCourse) return payload;

    return { ...payload, courseId: shared.newCourse.courseId };
  }

  private async resolveSharedContext(
    type: NotificationType,
    deeplink?: string,
  ): Promise<SharedContext | null> {
    // PROGRESS_START wants the same document, but only as the fallback source of
    // `{topic_name}` for a reader with no history to infer a topic from.
    //
    // So does ANY template pointed at the `new_course` destination, whatever its
    // own type: the app needs `courseId` in the payload to open a roadmap, and
    // without it the tap lands on Home. The admin screen offers that destination
    // on every template, so "Daily remind → Roadmap khoá mới" is a normal thing
    // to configure -- it was simply a dead tap before this.
    if (
      type !== NotificationType.NEW_COURSE &&
      type !== NotificationType.PROGRESS_START &&
      deeplink !== NotificationDeeplink.NEW_COURSE
    ) {
      return {};
    }

    const course = await this.courseRepository.findNewestPublished();
    if (!course) {
      // An empty catalog leaves the announcement with nothing to announce, so it
      // stands down. PROGRESS_START still has five wordings that name no topic,
      // so it goes out regardless.
      return type === NotificationType.NEW_COURSE ? null : {};
    }

    return {
      newCourse: {
        courseId: String((course as any)._id),
        title: (course as any).title,
        topicTitle: await this.skillsetTitle((course as any).skillsetId),
      },
    };
  }

  /**
   * Evaluates the type's trigger condition and collects what its copy needs.
   * Returns null when the user does not qualify — which is the normal case for
   * most users on most ticks.
   */
  private async resolveContext(
    type: NotificationType,
    userId: string,
    candidate: PushCandidate,
    shared: SharedContext,
  ): Promise<{
    variables: Record<string, string>;
    payload: Record<string, string>;
    meta: Record<string, unknown>;
  } | null> {
    const userName = candidate.name?.trim() || '';

    switch (type) {
      case NotificationType.DAILY_REMIND: {
        const quote = await this.quoteRepository.findRandom();
        const text = this.pickTranslation(
          (quote as any)?.content ?? (quote as any)?.quote,
          candidate.language,
        );
        // No quote in the collection means nothing worth waking a phone for.
        if (!text) return null;
        return {
          variables: { user_name: userName, quote: text },
          payload: {},
          meta: { quoteId: quote ? String((quote as any)._id) : '' },
        };
      }

      case NotificationType.PROGRESS_FINISH: {
        const stops = await this.userProgressRepository.findRecentStopAts(userId);
        // Put down AND not finished since — otherwise the nudge would chase a
        // lesson the reader already completed. Walks every recent course instead
        // of only the newest one: finishing the lesson you last stopped at does
        // not mean nothing is left unfinished elsewhere, and the old single-row
        // read turned that into "no notification at all".
        const stop = stops.find(
          item => !item.passedLessonIds.includes(item.lessonId),
        );
        if (!stop) return null;

        // The copy names the COURSE, not the lesson: a tap on this notification
        // lands on that course's roadmap (see `RESUME_LESSON`), so naming a
        // lesson promised a screen the reader never sees. The lesson is still
        // what identifies the stop — it just isn't what the sentence says.
        const course = await this.courseRepository.findById(stop.courseId);
        const courseName = this.pickTranslation(
          (course as any)?.title,
          candidate.language,
        );
        if (!courseName) return null;

        return {
          variables: {
            user_name: userName,
            course_name: courseName,
            // The course's skillset, for the wordings that name the topic the
            // reader is working on. Empty for a course with no skillset, which
            // makes the picker skip those wordings instead of rendering the
            // placeholder.
            topic_name: this.pickTranslation(
              await this.skillsetTitle((course as any)?.skillsetId),
              candidate.language,
            ),
            // Deprecated alias, deliberately fed the course name. Templates
            // already stored in Mongo still say `{lesson_name}`, and
            // `seedMissing` never rewrites an existing document — without this
            // a live template would push the literal placeholder to phones.
            // Remove once every environment's copy has been updated.
            lesson_name: courseName,
          },
          payload: {
            courseId: stop.courseId,
            lessonId: stop.lessonId,
            keypointId: stop.keypointId ?? '',
          },
          meta: {
            courseId: stop.courseId,
            courseName,
            lessonId: stop.lessonId,
            keypointId: stop.keypointId ?? '',
          },
        };
      }

      case NotificationType.PROGRESS_START: {
        const stops = await this.userProgressRepository.findRecentStopAts(userId);
        // The exact complement of the test above, run against the same read, so
        // a reader qualifies for one nudge or the other and never both. Somebody
        // who has never opened a lesson has no rows at all and lands here too —
        // the sheet's D0 case — as does somebody who finished everything.
        const unfinished = stops.find(
          item => !item.passedLessonIds.includes(item.lessonId),
        );
        if (unfinished) return null;

        // `{topic_name}` for the two wordings that name a subject. The course
        // this reader last touched is the closest thing to a declared interest,
        // and `findRecentStopAts` already returns newest-first, so it is one
        // lookup rather than a search.
        let topicName = '';
        if (stops.length > 0) {
          const lastCourse = await this.courseRepository.findById(
            stops[0].courseId,
          );
          topicName = this.pickTranslation(
            await this.skillsetTitle((lastCourse as any)?.skillsetId),
            candidate.language,
          );
        }

        let topicSource = topicName ? 'history' : 'none';
        if (!topicName && shared.newCourse) {
          // Nothing in the history to go on — a reader who has never started
          // anything. The newest course's topic is the one subject the product
          // is willing to suggest unprompted.
          topicName = this.pickTranslation(
            shared.newCourse.topicTitle,
            candidate.language,
          );
          if (topicName) topicSource = 'newest_course';
        }
        // Still empty is not a reason to stay silent: the picker drops the two
        // wordings that need it and the other five go out unchanged.

        return {
          variables: { user_name: userName, topic_name: topicName },
          payload: {},
          meta: { topicName, topicSource, touchedCourses: stops.length },
        };
      }

      case NotificationType.NEW_COURSE: {
        const course = shared.newCourse;
        if (!course) return null;

        const courseName = this.pickTranslation(
          course.title,
          candidate.language,
        );
        // A course with no title in any locale cannot be announced.
        if (!courseName) return null;

        return {
          variables: {
            user_name: userName,
            course_name: courseName,
            topic_name: this.pickTranslation(
              course.topicTitle,
              candidate.language,
            ),
          },
          payload: { courseId: course.courseId },
          meta: { courseId: course.courseId, courseName },
        };
      }

      case NotificationType.HABIT_TRACKING: {
        const habits = await this.userHabitRepository.findForUser(
          userId,
          UserHabitState.ACTIVE,
        );
        if (!habits?.length) return null;

        const habitIds = habits.map(habit => String((habit as any)._id));
        const doneToday = await this.habitCheckinRepository.findTodayForUserHabits(
          habitIds,
          this.startOfLocalDay(candidate.timezone),
        );
        const doneIds = new Set(
          (doneToday ?? [])
            .filter(checkin => (checkin as any).done)
            .map(checkin => String((checkin as any).userHabitId)),
        );
        const pending = habitIds.filter(id => !doneIds.has(id));
        if (pending.length === 0) return null;

        return {
          variables: { user_name: userName },
          payload: {},
          meta: { pendingHabits: pending.length },
        };
      }

      case NotificationType.WEEKLY_RECAP_READY:
      case NotificationType.WEEKLY_RECAP_REMINDER: {
        // The finished week's snapshot, if the reader has already opened it —
        // generation is lazy (first ask writes it, see WeekRecapService), so a
        // missing row is the NORMAL Monday-morning state, not an error.
        const recap = await this.weekRecapRepository.findForWeek(
          userId,
          this.lastWeekStart(new Date(), candidate.timezone),
        );

        // The reminder stands down once the recap has been VIEWED — the same
        // stamp that retires the in-app Monday popup. `dismissedAt` ("Để sau")
        // deliberately does not count: postponing the popup is not seeing the
        // week. The 10:00 announcement has no condition at all ("All users" on
        // the sheet).
        if (
          type === NotificationType.WEEKLY_RECAP_REMINDER &&
          (recap as any)?.viewedAt
        ) {
          return null;
        }

        const recapId = recap ? String((recap as any)._id) : '';
        return {
          variables: { user_name: userName },
          // Empty recapId tells the app "open my current one" — its poster
          // route fetches (and thereby generates) the week on a missing id.
          payload: { recapId },
          meta: recapId ? { recapId } : {},
        };
      }

      default:
        return null;
    }
  }

  /**
   * Admin "send me one now" — ignores schedule, condition and caps.
   *
   * [variantKey] pins the wording so an editor can check one sentence on a real
   * device; without it the same picker production uses decides, minus the
   * cooldown (this send is not logged, so it neither reads nor writes history).
   */
  async sendTest(type: NotificationType, userId: string, variantKey?: string) {
    const template = await this.templateService
      .findAll()
      .then(list => list.find(item => item.type === type));
    if (!template) throw new NotFoundException(`Unknown template: ${type}`);

    const user = await this.userRepository.findOne({ _id: userId } as any);
    if (!user) throw new NotFoundException('User not found');

    const tokens = (user.devices ?? [])
      .filter(device => !!device.pushToken)
      .map(device => device.pushToken as string);
    if (tokens.length === 0) {
      return { sent: false, reason: 'user has no push token' };
    }

    const shared = await this.resolveSharedContext(type, template.deeplink);
    const context = shared
      ? await this.resolveContext(type, userId, {
          _id: user._id,
          name: user.name,
          language: user.language,
          timezone: (user as any).timezone,
          devices: user.devices as any,
        }, shared)
      : null;

    // The real condition may not hold for the test user, and checking wording is
    // exactly what this endpoint is for, so an unmet condition falls back to
    // empty variables rather than refusing to send. `conditionMet` in the
    // response is what tells the two apart.
    const variables = context?.variables ?? {
      user_name: user.name ?? '',
      course_name: '',
      topic_name: '',
      lesson_name: '',
      quote: '',
    };

    const variants = variantsOf(template);
    const pick = variantKey
      ? this.pickRequestedVariant(variants, variantKey, user.language)
      : pickVariant({ variants, language: user.language, variables });
    if (!pick) {
      return {
        sent: false,
        // Two different problems, and the fix differs: a missing translation, or
        // a wording whose variable has nothing to fill it (every new-course
        // wording needs `{course_name}`, so an empty catalog lands here).
        reason: variantKey
          ? `variant ${variantKey} has no copy for this user's locale`
          : context
            ? 'no wording can render for this user (missing copy, or a variable with no value)'
            : 'trigger data unavailable, so every wording is missing a variable',
      };
    }

    const result = await this.firebaseService.sendToTokens(
      tokens,
      this.render(pick.copy.title, variables),
      this.render(pick.copy.body, variables),
      this.withDestinationPayload(template.deeplink, shared ?? {}, {
        type,
        deeplink: template.deeplink as NotificationDeeplink,
        ...(context?.payload ?? {}),
        test: 'true',
      }),
      // The test send must carry the image too, or the admin's only way to see
      // the artwork before a real send would be to fire the real send.
      template.imageUrl,
    );

    return {
      sent: result.successCount > 0,
      successCount: result.successCount,
      failureCount: result.failureCount,
      conditionMet: context !== null,
      // Which wording went out, so a random test send is still reproducible: the
      // editor can re-send that exact key.
      variantKey: pick.variant.key,
      // What FCM actually said. Without this the admin's only signal was
      // `failureCount: 1`, which reads the same for an expired token, an APNs
      // key missing for this bundle, and a Firebase outage -- three problems
      // with three completely different fixes.
      ...(result.failures.length ? { failures: result.failures } : {}),
    };
  }

  /** The wording an editor asked for by key, if it can render for this locale. */
  private pickRequestedVariant(
    variants: ReturnType<typeof variantsOf>,
    variantKey: string,
    language?: string,
  ): INotificationVariantPick | null {
    const variant = variants.find(item => item.key === variantKey);
    if (!variant) return null;
    const copy = copyForLocale(variant.copies, language);
    return copy ? { variant, copy } : null;
  }

  /**
   * A skillset's title translations, cached for
   * [SKILLSET_TITLE_TTL_MS]. Null for a course with no skillset, or a skillset id
   * that no longer resolves — `{topic_name}` then stays empty and the wordings
   * that need it drop out of the rotation.
   */
  private async skillsetTitle(skillsetId?: string): Promise<unknown> {
    if (!skillsetId) return null;

    const now = Date.now();
    const cached = this.skillsetTitleCache.get(skillsetId);
    if (cached && cached.expiresAt > now) return cached.title;

    let title: unknown = null;
    try {
      const skillset = await this.skillsetRepository.findById(skillsetId);
      title = (skillset as any)?.title ?? null;
    } catch (error: any) {
      // A malformed id casts badly; that is a content problem, not a reason to
      // abort everybody's notification.
      this.logger.warn(`Could not read skillset ${skillsetId}: ${error?.message}`);
    }

    this.skillsetTitleCache.set(skillsetId, {
      title,
      expiresAt: now + NotificationDispatchService.SKILLSET_TITLE_TTL_MS,
    });
    return title;
  }

  /**
   * How late a send may still go out, in minutes.
   *
   * The cron fires every minute, so the exact minute is normally hit dead on.
   * This is purely catch-up: a tick skipped by the `isRunning` guard, a deploy,
   * or a restart would otherwise drop that zone's notification for the whole day.
   * Re-sending is impossible regardless — `claimSlot` is atomic per
   * (user, type, local date) — so the only thing a window can cost is lateness.
   */
  private static readonly SEND_WINDOW_MINUTES = 15;

  /**
   * Every zone's current local hour+minute, read once per tick.
   *
   * Derived live rather than from a stored per-user offset: offsets move with
   * daylight saving, so a cached number would silently drift an hour twice a
   * year. `Intl` is the only thing that knows the current rule.
   */
  private zoneClocks(now: Date): Map<string, number> {
    // Memoised for the minute it describes. One tick now asks for this once per
    // live campaign on top of once for the scheduled types, and the answer is by
    // definition the same for all of them — rebuilding ~400 `Intl` formatters
    // per caller was the whole cost of letting the campaign worker loop.
    const minute = Math.floor(now.getTime() / 60_000);
    if (this.clockCache?.minute === minute) return this.clockCache.clocks;

    const clocks = new Map<string, number>();
    for (const zone of this.supportedTimezones()) {
      try {
        clocks.set(zone, this.localMinutesOfDay(now, zone));
      } catch {
        // Unknown zone on this platform — skip it rather than fail the tick.
      }
    }
    this.clockCache = { minute, clocks };
    return clocks;
  }

  private clockCache: { minute: number; clocks: Map<string, number> } | null =
    null;

  /**
   * Zones whose local clock has reached [hour]:[minute] and is still inside the
   * catch-up window.
   *
   * The window opens AT the send time and runs forward: it exists to catch up on
   * lateness, never to fire early. Wrap-around therefore matters in the other
   * direction than it first looks — a 23:58 send is still accepted from a zone
   * already reading 00:05 the NEXT day, which is why anything comparing dates
   * has to date the send time rather than the moment of the tick (see
   * `localDateAtSendTime`). Modulo arithmetic on minutes-of-day handles it
   * without special-casing midnight.
   */
  private timezonesDueAt(hour: number, minute: number, clocks: Map<string, number>): string[] {
    const target = hour * 60 + minute;
    const due: string[] = [];
    for (const [zone, localMinutes] of clocks) {
      const elapsed = (localMinutes - target + 1440) % 1440;
      if (elapsed < NotificationDispatchService.SEND_WINDOW_MINUTES) due.push(zone);
    }
    return due;
  }

  /** Minutes since local midnight in [timezone]. */
  private localMinutesOfDay(now: Date, timezone: string): number {
    const formatted = new Intl.DateTimeFormat('en-GB', {
      timeZone: timezone,
      hour: '2-digit',
      minute: '2-digit',
      hour12: false,
    }).format(now);
    const [hour, minute] = formatted.split(':').map(Number);
    return hour * 60 + minute;
  }

  /**
   * Every zone the platform knows, when it can enumerate them; otherwise a
   * pragmatic list covering the app's markets. Filtering by whether users
   * actually have a zone happens in the query, so a long list costs nothing.
   */
  private supportedTimezones(): string[] {
    const anyIntl = Intl as unknown as { supportedValuesOf?: (key: string) => string[] };
    if (typeof anyIntl.supportedValuesOf === 'function') {
      return anyIntl.supportedValuesOf('timeZone');
    }
    return [
      'Asia/Ho_Chi_Minh',
      'Asia/Bangkok',
      'Asia/Jakarta',
      'Asia/Kuala_Lumpur',
      'Asia/Manila',
      'Asia/Singapore',
      'Asia/Seoul',
      'Asia/Tokyo',
      'Asia/Shanghai',
      'Asia/Taipei',
      'Australia/Sydney',
      'Europe/London',
      'Europe/Paris',
      'America/New_York',
      'America/Los_Angeles',
      'UTC',
    ];
  }

  /** `YYYY-MM-DD` in the user's own zone. */
  private localDate(now: Date, timezone?: string): string {
    try {
      return new Intl.DateTimeFormat('en-CA', {
        timeZone: timezone || 'UTC',
        year: 'numeric',
        month: '2-digit',
        day: '2-digit',
      }).format(now);
    } catch {
      return now.toISOString().slice(0, 10);
    }
  }

  /**
   * Midnight of the user's current local day, as the UTC instant the check-in
   * rows are stored against.
   */
  private startOfLocalDay(timezone?: string): Date {
    const localDate = this.localDate(new Date(), timezone);
    return new Date(`${localDate}T00:00:00.000Z`);
  }

  /** ISO weekday (1 = Monday … 7 = Sunday) of the current local day in [zone]. */
  private localWeekdayIso(now: Date, zone: string): number | null {
    try {
      const name = new Intl.DateTimeFormat('en-GB', {
        timeZone: zone,
        weekday: 'short',
      }).format(now);
      const iso = { Mon: 1, Tue: 2, Wed: 3, Thu: 4, Fri: 5, Sat: 6, Sun: 7 }[
        name as 'Mon'
      ];
      return iso ?? null;
    } catch {
      // Unknown zone — the caller's filter then simply drops it, same as
      // zoneClocks does.
      return null;
    }
  }

  /**
   * `weekStart` of the week that has just FINISHED in [timezone] — the key
   * week-recap snapshots are stored under.
   *
   * Same convention as `weekBounds` (week-recap.helper): the local Monday's
   * DATE pinned at UTC midnight, so it is derived from the local date string
   * alone and needs no offset arithmetic. Computed from the local weekday
   * rather than assuming "today is Monday", so an admin moving the template to
   * another weekday still targets the correct finished week.
   */
  private lastWeekStart(now: Date, timezone?: string): Date {
    const todayLocal = this.localDate(now, timezone);
    const today = new Date(`${todayLocal}T00:00:00.000Z`);
    const mondayIndex = (today.getUTCDay() + 6) % 7;
    const msPerDay = 24 * 60 * 60 * 1000;
    return new Date(today.getTime() - (mondayIndex + 7) * msPerDay);
  }

  private pickTranslation(value: unknown, language?: string): string {
    if (!value) return '';
    if (typeof value === 'string') return value;
    const translations = value as Record<string, string | undefined>;
    const normalized = (language ?? '').toLowerCase().split(/[-_]/)[0];
    return (translations[normalized] || translations.en || '').trim();
  }

  private render(template: string, variables: Record<string, string>): string {
    if (!template) return '';
    return template.replace(/\{(\w+)\}/g, (match, key: string) =>
      variables[key] !== undefined ? variables[key] : match,
    );
  }
}
