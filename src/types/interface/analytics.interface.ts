export type UserEventKind = "event" | "screen";

export interface INameCount {
  name: string;
  count: number;
}

export interface IUserBehaviorSummary {
  totalEvents: number;
  activeDays: number;
  sessions: number;
  totalDurationMs: number;
  avgSessionMs: number;
  lastActiveAt: string | null;
  platforms: string[];
  appVersions: string[];
  topScreens: INameCount[];
  topEvents: INameCount[];
  // First time each `obd_*` event was seen. The step ORDER lives in
  // src/config/analyticsFunnel.ts — the API only reports timestamps.
  funnelFirstSeen: { name: string; at: string }[];
}

export interface IUserBehaviorSession {
  sessionId: string;
  startAt: string;
  endAt: string;
  durationMs: number;
  eventCount: number;
  firstScreen?: string;
  lastScreen?: string;
  appEnv?: string;
  appVersion?: string;
  platform?: string;
}

export interface IUserBehaviorSessionList {
  items: IUserBehaviorSession[];
  // True when the API hit its `limit` — the range holds more sessions than shown.
  truncated: boolean;
}

export interface IUserBehaviorEvent {
  name: string;
  kind: UserEventKind;
  clientTs: string;
  params?: Record<string, any>;
}

export interface IUserBehaviorEventList {
  items: IUserBehaviorEvent[];
  nextCursor: string | null;
}

export interface BehaviorRangeQuery {
  from?: string;
  to?: string;
  appEnv?: string;
}

export interface BehaviorEventsQuery {
  sessionId: string;
  namePrefix?: string;
  kind?: UserEventKind;
  cursor?: string;
  limit?: number;
}
