import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose';
import { SchemaTypes, Types } from 'mongoose';

import { AbstractDocument } from '@base/database/mongodb/abstract.schema';

import { CAMPAIGN_DEEPLINK_KEYS } from '../constant/campaign-deeplink.constant';
import {
  NotificationCampaignSendMode,
  NotificationCampaignStatus,
} from '../notification.enum';

/**
 * One manual push an operator composes and fires at a segment.
 *
 * Deliberately NOT a `notification_templates` row: a template is a standing
 * type with a daily rhythm and a per-user cooldown, while this is a one-off with
 * a lifecycle (draft → queued → sending → sent) and its own progress counters.
 * Forcing both into one document would have made every field on it optional.
 */
@Schema({ collection: 'notification_campaigns' })
export class NotificationCampaign extends AbstractDocument {
  /** Operator-facing label. Never shown to a reader. */
  @Prop({ required: true })
  name: string;

  /** `{ locale: { title, body } }`, same shape a template's copies use. */
  @Prop({ type: SchemaTypes.Mixed, default: {} })
  copies: Record<string, { title: string; body: string }>;

  /**
   * Ảnh kèm noti — URL tuyệt đối trên R2, dùng chung cho mọi locale.
   *
   * Một ảnh cho cả campaign chứ không phải một ảnh mỗi locale: ảnh marketing ở
   * đây không bake chữ vào, và bắt người vận hành chuẩn bị 5 ảnh mỗi lần gửi là
   * cái giá không đáng. Mongo thì additive nên thêm override per-locale về sau
   * không cần migration.
   *
   * `null` = noti chỉ có chữ, đúng như mọi campaign trước khi có field này.
   */
  @Prop({ type: String, default: null })
  imageUrl: string | null;

  /**
   * Khoá màn đích — của danh mục deeplink hoặc của các loại noti có lịch. Cố ý
   * KHÔNG ràng `enum NotificationDeeplink`: campaign trỏ được tới mọi màn trong
   * danh mục, và ràng theo enum đó là lý do dropdown từng mời chọn `habit` với
   * `library` mà lưu là 400.
   */
  @Prop({ type: String, enum: CAMPAIGN_DEEPLINK_KEYS, required: true })
  deeplink: string;

  /**
   * Tham số tuỳ chọn của đích, đã lọc theo danh mục (`sanitizeDeeplinkParams`).
   *
   * Tách khỏi `deeplink` chứ không nhét vào cùng chuỗi: khoá đó bị ràng
   * `enum CAMPAIGN_DEEPLINK_KEYS` ở cả DTO lẫn Mongoose, nên `paywall?variant=full`
   * là một giá trị 400 — và nó cũng là hợp đồng công khai đã nằm trong link đã
   * phát ra, không phải chỗ mang thêm dữ liệu.
   *
   * Bộ này được bơm thẳng vào payload push, nên nó được lọc TRƯỚC khi lưu và
   * spread TRƯỚC các khoá điều khiển ở chỗ gửi.
   */
  @Prop({ type: SchemaTypes.Mixed, default: {} })
  deeplinkParams: Record<string, string>;

  /** Target segments (OR). Empty = every push-reachable user. */
  @Prop({ type: [String], default: [] })
  segmentIds: string[];

  @Prop({
    type: String,
    enum: NotificationCampaignSendMode,
    default: NotificationCampaignSendMode.NOW,
  })
  sendMode: NotificationCampaignSendMode;

  /**
   * For [NotificationCampaignSendMode.LOCAL_HOUR]: the wall-clock time each
   * reader should see it at, in their own zone.
   */
  @Prop({ type: Number, min: 0, max: 23, default: 9 })
  localHour: number;

  @Prop({ type: Number, min: 0, max: 59, default: 0 })
  localMinute: number;

  /**
   * Which local day to send on (`YYYY-MM-DD`), for LOCAL_HOUR.
   *
   * Needed because "20:00 local" alone cannot say WHICH 20:00: the worker walks
   * zones as they reach the hour, and without a date it would fire again the
   * next day, forever.
   */
  @Prop({ type: String, default: null })
  scheduledDate: string | null;

  @Prop({
    type: String,
    enum: NotificationCampaignStatus,
    default: NotificationCampaignStatus.DRAFT,
  })
  status: NotificationCampaignStatus;

  /**
   * Resume cursor for NOW mode: the last `_id` already walked, ascending.
   *
   * A campaign to thousands of readers does not finish inside one cron tick, and
   * a pod can die mid-send. Paging by `_id > cursor` makes the next tick
   * continue instead of starting over — the send log
   * (`notification_campaign_sends`) is the second guard, but re-reading the
   * whole audience every minute would be its own problem.
   */
  @Prop({ type: SchemaTypes.ObjectId, default: null })
  cursorUserId: Types.ObjectId | null;

  /**
   * Zones already handled, for LOCAL_HOUR: a campaign is finished when every
   * zone that has users has passed the hour, which takes up to 26 hours.
   */
  @Prop({ type: [String], default: [] })
  processedZones: string[];

  /**
   * The zone set currently being walked, for LOCAL_HOUR.
   *
   * A zone cannot be marked processed the moment it is picked up any more: its
   * readers are paged over several ticks, and the 15-minute due window is
   * narrower than a large zone takes to drain. Pinning the set here keeps the
   * walk going after the window has closed, instead of dropping whoever had not
   * been reached yet — which is what the one-shot 5000-user query did silently.
   *
   * Empty means "no walk in progress, look for zones that have just come due".
   */
  @Prop({ type: [String], default: [] })
  activeZones: string[];

  /**
   * Resume cursor inside [activeZones], the LOCAL_HOUR twin of [cursorUserId].
   *
   * Kept as its own field rather than reusing that one: a campaign is only ever
   * in one mode, but two names that mean "where the walk is" in two different
   * orderings would be a trap the first time someone changes a mode.
   */
  @Prop({ type: SchemaTypes.ObjectId, default: null })
  zoneCursorUserId: Types.ObjectId | null;

  /**
   * Soft lock so two ticks — or two pods — never walk the same campaign at once.
   * A timestamp rather than a boolean so a worker that dies mid-batch releases
   * it by expiry instead of wedging the campaign in `sending` forever.
   */
  @Prop({ type: Date, default: null })
  leaseUntil: Date | null;

  @Prop({ type: Number, default: 0 })
  sentCount: number;

  @Prop({ type: Number, default: 0 })
  failedCount: number;

  /**
   * Reached but not sent to: no live token, or already logged for this campaign.
   * Kept apart from `failedCount` so a delivery problem never hides inside it.
   */
  @Prop({ type: Number, default: 0 })
  skippedCount: number;

  @Prop({ type: Date, default: null })
  startedAt: Date | null;

  @Prop({ type: Date, default: null })
  finishedAt: Date | null;

  @Prop({ type: String, default: null })
  lastError: string | null;

}

export const NotificationCampaignSchema =
  SchemaFactory.createForClass(NotificationCampaign);

// The worker's only query: campaigns it may pick up, oldest first.
NotificationCampaignSchema.index({ status: 1, leaseUntil: 1 });
