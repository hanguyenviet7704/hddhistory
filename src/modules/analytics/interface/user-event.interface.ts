import { Types } from 'mongoose';

import { UserEventKind } from '../enum/analytics.enum';

export interface IUserEvent {
  userId: Types.ObjectId;
  deviceId: string;
  sessionId: string;
  name: string;
  kind: UserEventKind;
  params: Record<string, any>;
  clientTs: Date;
  serverTs: Date;
  appEnv: string;
  appVersion: string;
  platform: string;
}

export interface IUserEventSession {
  sessionId: string;
  startAt: Date;
  endAt: Date;
  durationMs: number;
  eventCount: number;
  firstScreen?: string;
  lastScreen?: string;
  appEnv?: string;
  appVersion?: string;
  platform?: string;
}

export interface INameCount {
  name: string;
  count: number;
}

export interface IUserEventSummary {
  totalEvents: number;
  activeDays: number;
  sessions: number;
  totalDurationMs: number;
  avgSessionMs: number;
  lastActiveAt: Date | null;
  platforms: string[];
  appVersions: string[];
  topScreens: INameCount[];
  topEvents: INameCount[];
  // First time each event whose name starts with `funnelPrefix` was seen.
  // The ORDER of the funnel steps is owned by the admin panel, not by the API —
  // it changes whenever the onboarding flow changes and we don't want an api
  // deploy for that.
  funnelFirstSeen: { name: string; at: Date }[];
}
