import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose';
import { SchemaTypes, Types } from 'mongoose';

import { AbstractDocument } from '@base/database/mongodb/abstract.schema';

import { NotificationLogStatus } from '../notification.enum';

/**
 * One (campaign, user) delivery — the per-campaign idempotency guard.
 *
 * WHY ITS OWN COLLECTION, and not a `notification_logs` row.
 *
 * `notification_logs` is uniquely indexed on `(userId, type, localDate)`, and
 * that index is what stops a double cron tick from sending a scheduled type
 * twice. Campaign rows would collide with it: the second campaign of the day to
 * the same reader would be rejected by the index and silently never send. The
 * alternative — dropping and recreating that unique index to include a campaign
 * id — means live index surgery on the collection guarding the running cron, and
 * Mongoose only ADDS indexes on boot (it never drops the old one), so the stale
 * unique index would keep rejecting writes until someone dropped it by hand.
 *
 * A separate collection avoids all of that, and matches the product decision
 * that campaigns do NOT count toward the 4-notifications-per-day cap: their
 * sends are deliberately not part of the daily tally the dispatcher reads.
 */
@Schema({ collection: 'notification_campaign_sends' })
export class NotificationCampaignSend extends AbstractDocument {
  @Prop({ type: SchemaTypes.ObjectId, required: true })
  campaignId: Types.ObjectId;

  @Prop({ required: true })
  userId: string;

  @Prop({ type: String, enum: NotificationLogStatus, required: true })
  status: NotificationLogStatus;

  @Prop({ type: Date, default: Date.now })
  sentAt: Date;

  @Prop({ type: Number, default: 0 })
  deviceCount: number;

  @Prop({ type: Number, default: 0 })
  successCount: number;

  @Prop({ type: Number, default: 0 })
  failureCount: number;

  @Prop({ type: String, default: null })
  reason: string | null;

  /** Locale actually used, so a wording complaint can be traced back. */
  @Prop({ type: String, default: null })
  locale: string | null;
}

export const NotificationCampaignSendSchema = SchemaFactory.createForClass(
  NotificationCampaignSend,
);

// The guard itself: one row per campaign per user, so a retried batch or an
// overlapping tick cannot send the same campaign to the same reader twice.
NotificationCampaignSendSchema.index(
  { campaignId: 1, userId: 1 },
  { unique: true },
);
// The admin's per-campaign delivery list, newest first.
NotificationCampaignSendSchema.index({ campaignId: 1, sentAt: -1 });
