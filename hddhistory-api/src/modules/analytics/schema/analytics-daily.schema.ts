import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose';
import { SchemaTypes, Types } from 'mongoose';

import { AbstractDocument } from '@base/database/mongodb/abstract.schema';

/**
 * One pre-aggregated day of product metrics, written by
 * [AnalyticsRollupService] just after midnight.
 *
 * ## Why this collection exists
 *
 * `user_events` self-destructs after 90 days (TTL on `serverTs`). Without a
 * rollup, every number on the dashboard is permanently lost as it ages out —
 * the "so với kỳ trước" comparison starts coming back empty the moment the
 * comparison window crosses that line, and a quarter-over-quarter view is
 * impossible to ever build. This collection has **no TTL**: it is the long
 * memory, and it is small enough (one document per day per environment) that
 * keeping it forever costs nothing.
 *
 * ## Why the user ids are stored, not just counts
 *
 * Distinct users do not add up. A range's active-user count is the size of the
 * *union* of its days, not the sum, so a day that only remembers "412 users"
 * cannot answer "how many distinct users in July". At HDDhistory's scale a day holds
 * a few hundred ids (~12 bytes each), so the union stays exact for a few KB.
 * Drop this and every user metric silently becomes an over-count.
 *
 * The dashboard reads live `user_events` today — this is written from day one
 * so the history is there when the raw events are not.
 */
@Schema({ collection: 'analytics_daily' })
export class AnalyticsDaily extends AbstractDocument {
  /** YYYY-MM-DD in [DEFAULT_TIMEZONE], the same bucket the dashboard uses. */
  @Prop({ required: true })
  date: string;

  @Prop({ required: true })
  appEnv: string;

  @Prop({ type: [SchemaTypes.ObjectId], default: [] })
  activeUserIds: Types.ObjectId[];

  /** Accounts created this day — the denominator of the retention cohorts. */
  @Prop({ type: [SchemaTypes.ObjectId], default: [] })
  newUserIds: Types.ObjectId[];

  @Prop({ default: 0 })
  sessions: number;

  @Prop({ default: 0 })
  engagedSessions: number;

  @Prop({ default: 0 })
  events: number;

  @Prop({ default: 0 })
  totalDurationMs: number;

  /** Events per hour 0..23, so the peak-hour chart survives the TTL too. */
  @Prop({ type: [Number], default: () => new Array(24).fill(0) })
  hourlyEvents: number[];

  /** Distinct users per tracked event name, e.g. `{ obd_intro1_scr_view: 41 }`. */
  @Prop({ type: SchemaTypes.Mixed, default: {} })
  eventUsers: Record<string, number>;

  @Prop({ type: SchemaTypes.Mixed, default: {} })
  eventCounts: Record<string, number>;
}

export const AnalyticsDailySchema = SchemaFactory.createForClass(AnalyticsDaily);

// A re-run overwrites the same day instead of duplicating it — the same
// guarantee segment snapshots make, and what lets the cron be retried safely.
AnalyticsDailySchema.index({ date: 1, appEnv: 1 }, { unique: true });
