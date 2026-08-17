// Mirrors meup-api's `src/modules/analytics/interface/dashboard.interface.ts`.
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

export interface IUsersPage {
  range: IDashboardRange;
  compareRange: IDashboardRange | null;
  totals: IUserTotals;
  previousTotals: IUserTotals | null;
  daily: { date: string; active: number; new: number }[];
  retention: IRetentionPoint[];
  retentionByAppVersion: IRetentionByVersion[];
  byPlatform: INameValue[];
  byAppVersion: INameValue[];
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

export interface ISessionsPage {
  range: IDashboardRange;
  compareRange: IDashboardRange | null;
  totals: ISessionTotals;
  previousTotals: ISessionTotals | null;
  daily: { date: string; sessions: number; engagedSessions: number }[];
  hourly: IHourPoint[];
  depthBuckets: IDepthBucket[];
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

export interface ILearningPage {
  range: IDashboardRange;
  compareRange: IDashboardRange | null;
  milestones: {
    key: string;
    label: string;
    event: string;
    users: number;
    events: number;
    previousUsers: number | null;
  }[];
  topCourses: ITopContentRow[];
  topSkills: ITopContentRow[];
  daily: { date: string; keypointCompleted: number; lessonCompleted: number }[];
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
}
