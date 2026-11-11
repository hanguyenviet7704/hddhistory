import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose';

import { AbstractDocument } from '@base/database/mongodb/abstract.schema';

import { NotificationLogStatus, NotificationType } from '../notification.enum';

/**
 * One row per (user, type, local day) attempt — the admin monitoring screen reads
 * this, and the dispatcher reads it back as the ONLY source of truth for the
 * daily rules: once per type per day, at most two per day, and no habit nudge on
 * a day that already got a progress nudge.
 *
 * A skip is written too, with its reason. Without that, "why did this user get
 * nothing yesterday" would be unanswerable.
 */
@Schema({ collection: 'notification_logs' })
export class NotificationLog extends AbstractDocument {
  @Prop({ required: true })
  userId: string;

  @Prop({ required: true, enum: NotificationType })
  type: NotificationType;

  /**
   * The user's own calendar day as `YYYY-MM-DD`, NOT a UTC timestamp: the caps
   * are "per day" as the user experiences it, and near midnight a UTC date puts
   * two sends of one local day into different buckets.
   */
  @Prop({ required: true })
  localDate: string;

  @Prop({ required: true, enum: NotificationLogStatus })
  status: NotificationLogStatus;

  @Prop({ type: Date, default: Date.now })
  sentAt: Date;

  @Prop()
  locale?: string;

  @Prop()
  title?: string;

  @Prop()
  body?: string;

  @Prop()
  deeplink?: string;

  /** Why a SKIPPED row was skipped, or the transport error on FAILED. */
  @Prop()
  reason?: string;

  @Prop({ type: Number, default: 0 })
  deviceCount: number;

  @Prop({ type: Number, default: 0 })
  successCount: number;

  @Prop({ type: Number, default: 0 })
  failureCount: number;

  /** Snapshot of what the copy was rendered with (lesson name, quote id, …). */
  @Prop({ type: Object })
  meta?: Record<string, unknown>;
}

export const NotificationLogSchema =
  SchemaFactory.createForClass(NotificationLog);

// The dispatcher's hot path: "what has this user already had today".
NotificationLogSchema.index({ userId: 1, localDate: 1 });
// One row per user/type/day — also the guard that makes a double cron tick (two
// workers, or a retry) unable to send the same notification twice.
NotificationLogSchema.index(
  { userId: 1, type: 1, localDate: 1 },
  { unique: true },
);
// Admin monitoring list, newest first.
NotificationLogSchema.index({ sentAt: -1 });
