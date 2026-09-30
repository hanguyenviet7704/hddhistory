/**
 * The scheduled notifications of Phase 1 (see the "Noti" sheet). Each fires once
 * a day at its own LOCAL hour and carries its own trigger condition; the values
 * are stored on every log row, so renaming one rewrites history — add instead.
 */
export enum NotificationType {
  /** 08:00 — a motivation quote. No condition beyond "has a device". */
  DAILY_REMIND = 'daily_remind',
  /** 11:45 — a lesson was left unfinished. */
  PROGRESS_FINISH = 'progress_finish',
  /**
   * 11:45 — the same slot as PROGRESS_FINISH, for the readers it cannot reach:
   * nothing started yet, or everything started has been finished.
   *
   * The sheet writes the two as one row with two segments; they are two types
   * here because the destination and all seven wordings differ, and both live at
   * the template level. Their conditions are complements of each other evaluated
   * against the same read, so a reader qualifies for exactly one — which is what
   * implements the sheet's "exclude anyone already sent segment 1 today" without
   * a cross-type rule.
   */
  PROGRESS_START = 'progress_start',
  /** 21:00 — at least one habit is still unchecked today. */
  HABIT_TRACKING = 'habit_tracking',
  /**
   * 20:00 — the newest published course, pushed every day.
   *
   * Deliberately unconditional: it re-announces the same course on the next day
   * when nothing newer has been created, rather than going quiet. Only the
   * wording rotates (see the variant picker), which is why this type ships with
   * several variants instead of one sentence.
   */
  NEW_COURSE = 'new_course',
  /**
   * Monday 10:00 — last week's recap is ready ("6. Weekly recap" on the sheet,
   * Nhắc lần 1). The first WEEKLY type: its template carries `localWeekday`,
   * which the daily five leave unset.
   *
   * Unconditional beyond "has a device", exactly as the sheet's audience says
   * ("All users"). The snapshot itself is generated lazily on the reader's
   * first ask (see `WeekRecapService`), so its absence at send time means
   * nothing — the poster builds itself when the tap lands.
   */
  WEEKLY_RECAP_READY = 'weekly_recap_ready',
  /**
   * Monday 19:00 — the same recap, for readers who have not OPENED it yet
   * (Nhắc lần 2). "Opened" is the server's own `viewedAt` stamp on the week's
   * snapshot; a reader with no snapshot row has by definition not opened it
   * and is exactly who this is for.
   */
  WEEKLY_RECAP_REMINDER = 'weekly_recap_reminder',
  /**
   * The AI Coach's commitment reminder (④) — "khi họp nhóm — nói ra ý mình".
   *
   * The one type whose SEND TIME is not this enum's business: the reader picks
   * an hour per commitment when they make it, so `localHour` on its template is
   * unused and `dispatchDueNotifications` skips it entirely. The template row
   * still exists, and has to — it carries the five locales of the sentence
   * frame the reader's own words are dropped into, plus the deeplink.
   *
   * See `CoachPlanReminderDispatcher`, which owns the schedule half.
   */
  COACH_PLAN_REMINDER = 'coach_plan_reminder',
  /**
   * Nhắc học theo GIỜ USER CHỌN ở onboarding (S8). `localHour` của template trơ
   * như coach_plan_reminder; giờ thật nằm ở `users.studyReminderTime`. Xem
   * `OnboardingStudyReminderDispatcher`.
   */
  ONBOARDING_STUDY_REMINDER = 'onboarding_study_reminder',
}

export enum NotificationLogStatus {
  SENT = 'sent',
  /** Every device token Firebase had for the user was rejected. */
  FAILED = 'failed',
  /**
   * Deliberately not sent: the daily cap, the "no habit nudge after a progress
   * nudge" rule, notifications switched off, or no copy for the locale. Logged
   * rather than dropped so the reason is answerable a week later.
   */
  SKIPPED = 'skipped',
}

/**
 * Where a tap lands. The client maps these to routes — the server never sends a
 * raw path, so a route rename does not need a config migration.
 */
export enum NotificationDeeplink {
  HOME = 'home',
  /** The keypoint the reader stopped at (see `UserProgress.stopAt`). */
  RESUME_LESSON = 'resume_lesson',
  HABIT_TRACKER = 'habit_tracker',
  /**
   * The course the notification is about — its roadmap, from the payload's
   * `courseId`. App builds that predate this value log it as unsupported and
   * simply open the app, so an old install degrades to "no navigation" rather
   * than landing somewhere wrong.
   */
  NEW_COURSE = 'new_course',
  /**
   * The Explore tab — the catalog, with no course pre-selected.
   *
   * Where the "nothing left unfinished" nudge wants to land, since it names no
   * particular course. The app only learns this value in a release that adds it
   * to its own destination switch; older installs log it as unsupported and stay
   * put. That is why `progress_start` ships pointing at HOME instead, to be
   * flipped here from the admin screen once such a build is out.
   */
  EXPLORE = 'explore',
  /**
   * The week-recap poster ("Hành trình tuần qua"). The payload carries
   * `recapId` when the week's snapshot already exists — the app can pass it
   * straight to the poster route — and an empty string when it does not, which
   * the poster route treats as "load my current one" (generating it on that
   * first ask). Installs that predate this value log it and just open the app.
   */
  WEEK_RECAP = 'week_recap',
  /**
   * The Coach sheet, opened on the commitment the push is about — its `planId`
   * rides in the payload. Installs that predate this value log it as
   * unsupported and simply open the app, which is the right degradation: the
   * bubble is on Home anyway.
   */
  COACH = 'coach',
}

/** How a manual campaign reaches its audience. */
export enum NotificationCampaignSendMode {
  /** Everyone as fast as the worker can page through them. */
  NOW = 'now',
  /**
   * At `localHour:localMinute` in each reader's own zone on `scheduledDate` —
   * the same contract the scheduled types use, so nobody is woken at 3am.
   */
  LOCAL_HOUR = 'local_hour',
}

export enum NotificationCampaignStatus {
  DRAFT = 'draft',
  /** Operator pressed send/schedule; the worker owns it from here. */
  QUEUED = 'queued',
  SENDING = 'sending',
  SENT = 'sent',
  CANCELLED = 'cancelled',
  FAILED = 'failed',
}
