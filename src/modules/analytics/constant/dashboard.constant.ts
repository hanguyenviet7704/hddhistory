// Event names the product dashboard counts on, kept in one place so a rename in
// the app is a one-line change here rather than a hunt through aggregations.
//
// These are the fired strings from the Flutter app's `TrackingKey`
// (`lib/core/constants/manual/tracking_key.dart`) — not the Dart constant
// names. Anything missing from the collection simply reports zero; nothing
// here throws, because an app that stops firing an event must not 500 the
// dashboard.

/** Every onboarding event shares this prefix. */
export const ONBOARDING_EVENT_PREFIX = 'obd_';

/** Screen-view events are the funnel's steps; clicks and swipes are not. */
export const ONBOARDING_STEP_SUFFIX = '_scr_view';

/** First onboarding screen — the funnel's denominator. */
export const ONBOARDING_FIRST_STEP = 'obd_intro1_scr_view';

/** Reaching this screen means the flow was finished. */
export const ONBOARDING_COMPLETED_STEP = 'obd_complete_scr_view';

/**
 * The learning milestones, in the order a user passes them. `users` counts
 * distinct people, so a course reread does not inflate the funnel.
 *
 * Step 2 is the *read* screen rather than the intro screen: opening a keypoint
 * and actually entering its content are different acts, and the funnel is only
 * honest if the middle step means "started reading".
 */
export const LEARNING_MILESTONES = [
  { key: 'roadmapOpened', label: 'Xem lộ trình', event: 'roadmap_scr_view' },
  {
    key: 'keypointRead',
    label: 'Bắt đầu đọc keypoint',
    event: 'keypoint_read_scr_view',
  },
  {
    key: 'keypointCompleted',
    label: 'Hoàn thành keypoint',
    event: 'keypoint_complete_scr_view',
  },
  {
    key: 'lessonCompleted',
    label: 'Hoàn thành bài',
    event: 'lesson_finish_scr_view',
  },
] as const;

/**
 * The four rankings of "which course", each answering a different question and
 * therefore keyed on a different event. Same shape, so one query serves all
 * four and the panel just slices it.
 */
export const COURSE_RANKINGS = [
  {
    key: 'firstChoice',
    label: 'Khoá học đầu tiên user chọn',
    hint: 'Khoá được chọn ở bước cuối onboarding',
    event: 'obd_course_select',
  },
  {
    key: 'opened',
    label: 'Lượt mở khoá học',
    hint: 'Người vào xem lộ trình khoá',
    event: 'roadmap_scr_view',
  },
  {
    key: 'read',
    label: 'Lượt học',
    hint: 'Người vào đọc bài trong khoá',
    event: 'keypoint_read_scr_view',
  },
  {
    key: 'completed',
    label: 'Hoàn thành cao nhất',
    hint: 'Xếp theo lượt hoàn thành bài',
    event: 'keypoint_complete_scr_view',
  },
] as const;

/** Rows per course ranking list. */
export const COURSE_RANKING_LIMIT = 7;

/** How many courses each age group lists. */
export const AGE_INTEREST_LIMIT = 6;

/** Params carrying the content identity, used for the top-course/skill lists. */
export const COURSE_NAME_PARAM = 'params.course_name';
export const COURSE_ID_PARAM = 'params.course_id';
export const SKILL_NAME_PARAM = 'params.skill_name';
export const SKILL_ID_PARAM = 'params.skill_id';

/**
 * GA4's engaged-session rule, mirrored so our number means the same thing as
 * the one the team already reads in Firebase: a session counts as engaged when
 * it lasted at least 10 seconds or covered at least 2 screens.
 */
export const ENGAGED_SESSION_MIN_MS = 10_000;
export const ENGAGED_SESSION_MIN_SCREENS = 2;

/**
 * Days are bucketed in Vietnam time, not UTC. Bucketing in UTC shifts every
 * "peak hour" reading by 7 hours and splits an evening study session across two
 * calendar days.
 */
export const DEFAULT_TIMEZONE = 'Asia/Ho_Chi_Minh';

/**
 * Our own dev/stg traffic outnumbers nothing yet, but it would quietly corrupt
 * every number here, so the dashboard is production-only unless asked otherwise.
 */
export const DEFAULT_APP_ENV = 'prod';

/**
 * Retention offsets reported by the users page.
 *
 * Day 0 is included on purpose: it is ~100% by construction (a cohort is
 * defined by signing up that day) and that is exactly why the curve needs it —
 * it is the baseline the drop to day 1 is read against.
 */
export const RETENTION_OFFSETS = [0, 1, 2, 3, 7, 14] as const;

/** The two offsets the summary cards single out. */
export const RETENTION_HEADLINE_OFFSETS = [1, 7] as const;

/** Trailing windows for the WAU / MAU cards, in days. */
export const ACTIVE_WINDOWS = { wau: 7, mau: 28 } as const;

/** Countries listed before the tail is folded away. */
export const COUNTRY_LIST_LIMIT = 8;

/** How many rows the "top courses"/"top skills" lists return. */
export const TOP_LIST_LIMIT = 10;

/** Session-depth histogram edges (events per session). */
export const SESSION_DEPTH_BUCKETS = [1, 2, 6, 11, 21, 51] as const;

/**
 * A session this long is someone who settled in to study.
 */
export const LONG_SESSION_MS = 20 * 60 * 1000;

/**
 * A session this short is a glance — opened the app and left. Reported beside
 * the long-session share because the two together say more than an average
 * ever could: the same mean comes out of "everyone stays 3 minutes" and "half
 * bounce, half study for six".
 */
export const BOUNCE_SESSION_MS = 30 * 1000;

/**
 * Percentiles reported for session length.
 *
 * Computed by sorting and indexing rather than with `$percentile`/`$median`,
 * which need MongoDB 7 — a version this deployment cannot assume. At a few
 * thousand sessions per period the sort is free either way.
 */
export const DURATION_PERCENTILES = { p25: 0.25, median: 0.5, p75: 0.75 };

/**
 * What counts as "học bài" in the activity heatmap, as opposed to any app
 * activity at all. Matches the keypoint/lesson/roadmap event families rather
 * than a fixed list, so a new screen in the reader flow is included the day it
 * ships.
 */
export const LEARNING_EVENT_PATTERN = '^(keypoint|lesson|roadmap)_';
