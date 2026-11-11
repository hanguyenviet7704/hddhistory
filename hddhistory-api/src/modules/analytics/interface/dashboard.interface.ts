// Shapes returned by the admin product dashboard. Every page returns its own
// range + the comparison range it was measured against, so the panel never has
// to re-derive what "so với kỳ trước" meant.

export interface IDashboardRange {
  from: Date;
  to: Date;
  /** Inclusive day count — what the header prints as "40 ngày". */
  days: number;
}

/** Resolved query, after defaults are applied. */
export interface IDashboardFilter {
  from: Date;
  to: Date;
  appEnv?: string;
  platform?: string;
  appVersion?: string;
  timezone: string;
}

export interface IDailyPoint {
  /** YYYY-MM-DD in the requested timezone. */
  date: string;
  value: number;
}

export interface INameValue {
  name: string;
  value: number;
}

export interface IUserTotals {
  active: number;
  new: number;
  returning: number;
}

export interface IRetentionPoint {
  /** Day offset from signup: 1 = D1, 7 = D7. */
  offset: number;
  /** Users whose cohort is old enough for this offset to be measurable. */
  cohortUsers: number;
  retainedUsers: number;
  /** Null when no cohort is mature yet — the UI must say so, not print 0%. */
  rate: number | null;
}

export interface IRetentionByVersion {
  appVersion: string;
  points: IRetentionPoint[];
}

export interface IRetentionByPlatform {
  platform: string;
  points: IRetentionPoint[];
}

/**
 * Rolling-window activity, the shape every app measures itself by.
 *
 * `mauAtStart` is the same 28-day window anchored at the start of the range, so
 * the card can say how much the base grew rather than only how big it is.
 * Stickiness is DAU/MAU — how much of the monthly base shows up on a given day.
 */
export interface IActiveWindows {
  dau: number;
  wau: number;
  mau: number;
  mauAtStart: number;
  stickiness: number | null;
  /** The day DAU was measured on — the last day of the range. */
  dauDate: string;
}

export interface IDemographics {
  byCountry: INameValue[];
  byAge: INameValue[];
  /**
   * False when the field simply is not collected, so the panel can say that
   * instead of showing an empty chart that looks like a data outage.
   */
  hasCountryData: boolean;
  hasAgeData: boolean;
}

export interface IUsersPage {
  range: IDashboardRange;
  compareRange: IDashboardRange | null;
  totals: IUserTotals;
  previousTotals: IUserTotals | null;
  daily: {
    date: string;
    active: number;
    new: number;
  }[];
  /** DAU split by platform — the two lines of the daily-active chart. */
  dailyByPlatform: {
    date: string;
    platform: string;
    users: number;
  }[];
  activeWindows: IActiveWindows;
  retention: IRetentionPoint[];
  retentionByAppVersion: IRetentionByVersion[];
  retentionByPlatform: IRetentionByPlatform[];
  byPlatform: INameValue[];
  byAppVersion: INameValue[];
  demographics: IDemographics;
}

export interface ISessionTotals {
  sessions: number;
  engagedSessions: number;
  /** 0..1; the UI formats it. Null when there were no sessions at all. */
  engagementRate: number | null;
  avgDurationMs: number;
  avgEvents: number;
  avgScreens: number;
  activeUsers: number;
  /** Sessions per active user — how often someone came back within the range. */
  sessionsPerUser: number | null;
}

export interface IHourPoint {
  /** 0..23 in the requested timezone. */
  hour: number;
  sessions: number;
  events: number;
}

export interface IDepthBucket {
  /** Inclusive lower edge in events; `null` upper edge means "and above". */
  from: number;
  to: number | null;
  sessions: number;
}

/**
 * How long a session lasts, described by percentiles rather than a mean.
 *
 * An average session length is close to meaningless here: a handful of sessions
 * left open for an hour drag it far above anything a real user experiences. The
 * median says what a typical session is, and P25–P75 says how spread out the
 * rest are.
 */
export interface ISessionDurations {
  medianMs: number | null;
  p25Ms: number | null;
  p75Ms: number | null;
  /** Median among engaged sessions only — time when someone was actually using it. */
  engagedMedianMs: number | null;
  /** Share of sessions over [LONG_SESSION_MS]. */
  longSessionRate: number | null;
  /** Share of sessions under [BOUNCE_SESSION_MS] — opened and left. */
  bounceRate: number | null;
}

export interface IWeekdayDuration {
  /** 1 = Sunday … 7 = Saturday, matching Mongo's `$dayOfWeek`. */
  weekday: number;
  medianMs: number | null;
  sessions: number;
}

export interface IVersionDuration {
  appVersion: string;
  medianMs: number | null;
  sessions: number;
}

/** One cell of the weekday × hour activity grid. */
export interface IHeatmapCell {
  weekday: number;
  hour: number;
  /** Distinct users active in that slot. */
  users: number;
}

export interface ISessionsPage {
  range: IDashboardRange;
  compareRange: IDashboardRange | null;
  totals: ISessionTotals;
  previousTotals: ISessionTotals | null;
  daily: {
    date: string;
    sessions: number;
    engagedSessions: number;
  }[];
  hourly: IHourPoint[];
  depthBuckets: IDepthBucket[];
  durations: ISessionDurations;
  byWeekday: IWeekdayDuration[];
  byAppVersion: IVersionDuration[];
  /**
   * Two readings of the same grid: everything the app saw, and only the
   * keypoint/lesson/roadmap events. The panel toggles between them without a
   * second request.
   */
  heatmap: {
    all: IHeatmapCell[];
    learning: IHeatmapCell[];
  };
}

export interface IFunnelStep {
  event: string;
  users: number;
  /** Share of the first step's users still present, 0..1. */
  passRate: number | null;
  /** Users lost since the previous step. */
  dropUsers: number;
  dropRate: number | null;
}

export interface IOnboardingPage {
  range: IDashboardRange;
  compareRange: IDashboardRange | null;
  started: number;
  completed: number;
  completionRate: number | null;
  previous: {
    started: number;
    completed: number;
    completionRate: number | null;
  } | null;
  steps: IFunnelStep[];
  /** The step that loses the most people — what the summary card calls out. */
  biggestDrop: IFunnelStep | null;
}

export interface ITopContentRow {
  id: string | null;
  name: string;
  users: number;
  events: number;
}

export interface ILearningMilestone {
  key: string;
  label: string;
  event: string;
  users: number;
  events: number;
  previousUsers: number | null;
  /** Share of the first milestone's users still here — the funnel's shape. */
  passRate: number | null;
  /** Distinct users per platform, so a step can be read per OS. */
  byPlatform: INameValue[];
}

/** One "which course" ranking; four of them, each keyed on its own event. */
export interface ICourseRanking {
  key: string;
  label: string;
  hint: string;
  event: string;
  rows: ITopContentRow[];
}

export interface IAgeInterest {
  age: string;
  /** Distinct users of this age with any learning activity in the range. */
  users: number;
  interested: ITopContentRow[];
  completed: ITopContentRow[];
}

export interface ILearningPage {
  range: IDashboardRange;
  compareRange: IDashboardRange | null;
  milestones: ILearningMilestone[];
  /**
   * Raw volume beside the funnel's people-counts: screens opened, and keypoint
   * completions as events rather than as distinct finishers.
   */
  engagement: {
    screenViews: number;
    previousScreenViews: number | null;
    keypointCompletions: number;
    keypointCompletionUsers: number;
  };
  /** The single most-interacted course of the period. */
  heroCourse: ITopContentRow | null;
  topCourses: ITopContentRow[];
  topSkills: ITopContentRow[];
  courseRankings: ICourseRanking[];
  /**
   * Courses by age band. Empty when nobody in the range has an age on their
   * profile — the panel says so rather than drawing empty tabs.
   */
  byAge: IAgeInterest[];
  daily: {
    date: string;
    keypointCompleted: number;
    lessonCompleted: number;
  }[];
}

/**
 * One app version measured on the four "how deep is a session" metrics.
 *
 * Together they answer whether a release made people study more or just visit
 * more: duration and lessons-per-session go up when the app got better at
 * holding attention, while sessions-per-user-per-day going *down* alongside
 * them is the signature of fewer, longer visits rather than a regression.
 */
export interface IVersionDepth {
  appVersion: string;
  sessions: number;
  users: number;
  /** Median, not mean — a session left open for an hour must not set the tone. */
  sessionMedianMs: number | null;
  lessonsPerSession: number | null;
  /** Share of that version's users who finished at least one keypoint. */
  completionRate: number | null;
  sessionsPerUserPerDay: number | null;
}

/**
 * Change from the oldest version in the range to the newest. Rates are reported
 * in percentage points (`completionRatePoints`) rather than as a percentage of
 * a percentage, which is the usual way this number gets mangled.
 */
export interface IVersionDepthDeltas {
  sessionDurationPct: number | null;
  lessonsPerSessionPct: number | null;
  completionRatePoints: number | null;
  sessionsPerUserPerDayPct: number | null;
  from: string | null;
  to: string | null;
}

export interface IOverviewPage {
  range: IDashboardRange;
  compareRange: IDashboardRange | null;
  users: IUserTotals & { previous: IUserTotals | null };
  retention: IRetentionPoint[];
  sessions: {
    total: number;
    engagementRate: number | null;
    previousTotal: number | null;
  };
  onboarding: {
    started: number;
    completed: number;
    completionRate: number | null;
    biggestDrop: IFunnelStep | null;
  };
  learning: {
    roadmapOpened: number;
    lessonCompleted: number;
    topCourse: ITopContentRow | null;
    topSkill: ITopContentRow | null;
  };
  /** Peak study hours, highest first — the "khung giờ vàng" line. */
  peakHours: IHourPoint[];
  /** Session depth compared across app versions, oldest to newest. */
  versionDepth: {
    versions: IVersionDepth[];
    deltas: IVersionDepthDeltas;
  };
}

/** One pre-aggregated day, written by the nightly rollup. */
export interface IAnalyticsDailyTotals {
  activeUsers: number;
  newUsers: number;
  sessions: number;
  engagedSessions: number;
  events: number;
  totalDurationMs: number;
}
