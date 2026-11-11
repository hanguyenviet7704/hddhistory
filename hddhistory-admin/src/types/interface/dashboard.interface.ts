// Mirrors hddhistory-api's `src/modules/analytics/interface/dashboard.interface.ts`.
// Rates are `number | null` on purpose: null means "not measurable yet" (no
// denominator, or a cohort too young to have a D7 number) and must render as
// "chưa đủ dữ liệu", never as 0%.

export interface IDashboardRange {
  from: string;
  to: string;
  days: number;
}

export interface IDashboardQuery {
  from?: string;
  to?: string;
  appEnv?: string;
  platform?: string;
  appVersion?: string;
  timezone?: string;
  compare?: boolean;
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
  offset: number;
  cohortUsers: number;
  retainedUsers: number;
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

/** Rolling-window activity: DAU / WAU / MAU and how sticky the base is. */
export interface IActiveWindows {
  dau: number;
  wau: number;
  mau: number;
  mauAtStart: number;
  stickiness: number | null;
  dauDate: string;
}

export interface IDemographics {
  byCountry: INameValue[];
  byAge: INameValue[];
  /** False = the field is not collected, which is not the same as "no data". */
  hasCountryData: boolean;
  hasAgeData: boolean;
}

export interface IUsersPage {
  range: IDashboardRange;
  compareRange: IDashboardRange | null;
  totals: IUserTotals;
  previousTotals: IUserTotals | null;
  daily: { date: string; active: number; new: number }[];
  dailyByPlatform: { date: string; platform: string; users: number }[];
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
  engagementRate: number | null;
  avgDurationMs: number;
  avgEvents: number;
  avgScreens: number;
  activeUsers: number;
  sessionsPerUser: number | null;
}

export interface IHourPoint {
  hour: number;
  sessions: number;
  events: number;
}

export interface IDepthBucket {
  from: number;
  to: number | null;
  sessions: number;
}

/** Session length described by percentiles — a mean is meaningless here. */
export interface ISessionDurations {
  medianMs: number | null;
  p25Ms: number | null;
  p75Ms: number | null;
  engagedMedianMs: number | null;
  longSessionRate: number | null;
  bounceRate: number | null;
}

export interface IWeekdayDuration {
  /** 1 = Sunday … 7 = Saturday. */
  weekday: number;
  medianMs: number | null;
  sessions: number;
}

export interface IVersionDuration {
  appVersion: string;
  medianMs: number | null;
  sessions: number;
}

export interface IHeatmapCell {
  weekday: number;
  hour: number;
  users: number;
}

export interface ISessionsPage {
  range: IDashboardRange;
  compareRange: IDashboardRange | null;
  totals: ISessionTotals;
  previousTotals: ISessionTotals | null;
  daily: { date: string; sessions: number; engagedSessions: number }[];
  hourly: IHourPoint[];
  depthBuckets: IDepthBucket[];
  durations: ISessionDurations;
  byWeekday: IWeekdayDuration[];
  byAppVersion: IVersionDuration[];
  heatmap: {
    all: IHeatmapCell[];
    learning: IHeatmapCell[];
  };
}

export interface IFunnelStep {
  event: string;
  users: number;
  passRate: number | null;
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
  passRate: number | null;
  byPlatform: INameValue[];
}

export interface ICourseRanking {
  key: string;
  label: string;
  hint: string;
  event: string;
  rows: ITopContentRow[];
}

export interface IAgeInterest {
  age: string;
  users: number;
  interested: ITopContentRow[];
  completed: ITopContentRow[];
}

export interface ILearningPage {
  range: IDashboardRange;
  compareRange: IDashboardRange | null;
  milestones: ILearningMilestone[];
  engagement: {
    screenViews: number;
    previousScreenViews: number | null;
    keypointCompletions: number;
    keypointCompletionUsers: number;
  };
  heroCourse: ITopContentRow | null;
  topCourses: ITopContentRow[];
  topSkills: ITopContentRow[];
  courseRankings: ICourseRanking[];
  byAge: IAgeInterest[];
  daily: { date: string; keypointCompleted: number; lessonCompleted: number }[];
}

/** One app version on the four session-depth measures. */
export interface IVersionDepth {
  appVersion: string;
  sessions: number;
  users: number;
  sessionMedianMs: number | null;
  lessonsPerSession: number | null;
  completionRate: number | null;
  sessionsPerUserPerDay: number | null;
}

export interface IVersionDepthDeltas {
  sessionDurationPct: number | null;
  lessonsPerSessionPct: number | null;
  /** In percentage points: 67% → 80% is +0.13, shown as "+13 điểm". */
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
  peakHours: IHourPoint[];
  versionDepth: {
    versions: IVersionDepth[];
    deltas: IVersionDepthDeltas;
  };
}
