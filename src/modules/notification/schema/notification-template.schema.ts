import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose';
import { SchemaTypes } from 'mongoose';

import { AbstractDocument } from '@base/database/mongodb/abstract.schema';

import {
  NotificationDeeplink,
  NotificationType,
} from '../notification.enum';

/** Title + body for one locale. */
export interface INotificationCopy {
  title: string;
  body: string;
}

/**
 * One alternative wording of a notification, in every locale it has.
 *
 * [key] is assigned by the server (`v1`, `v2`, …) and is what the anti-repeat
 * memory stores — NOT the array index. An editor who deletes or reorders a
 * variant would otherwise make every log row point at a different sentence than
 * the one that was actually sent, and the "not the same wording as the last three
 * days" rule would start comparing against the wrong history.
 */
export interface INotificationVariant {
  key: string;
  copies: Record<string, INotificationCopy>;
}

/**
 * Editable content and timing for one notification type — one document per type.
 *
 * Copy lives here rather than in the app bundle so wording can change without a
 * release, which is the whole point of the admin import/export screen.
 */
@Schema({ collection: 'notification_templates' })
export class NotificationTemplate extends AbstractDocument {
  @Prop({ required: true, unique: true, enum: NotificationType })
  type: NotificationType;

  @Prop({ type: Boolean, default: false })
  enabled: boolean;

  /**
   * Hour of the user's OWN day, 0-23 (08 / 14 / 21 in Phase 1). Stored per type
   * so the schedule is data, not a constant compiled into the scheduler.
   */
  @Prop({ type: Number, required: true, min: 0, max: 23 })
  localHour: number;

  /**
   * Minute within [localHour], 0-59. Optional and defaulting to 0 so every
   * template written before this field existed keeps meaning "on the hour"
   * without a migration.
   */
  @Prop({ type: Number, default: 0, min: 0, max: 59 })
  localMinute: number;

  /**
   * ISO weekday the template fires on — 1 = Monday … 7 = Sunday — evaluated in
   * each reader's OWN zone, like the hour. Absent (the daily five) means every
   * day; the weekly-recap pair ships with 1. Nullable rather than defaulting so
   * templates written before this field existed keep firing daily untouched.
   */
  @Prop({ type: Number, min: 1, max: 7 })
  localWeekday?: number;

  @Prop({ type: String, enum: NotificationDeeplink, required: true })
  deeplink: NotificationDeeplink;

  /**
   * Ảnh kèm noti — URL tuyệt đối trên R2, dùng chung cho mọi locale VÀ mọi
   * variant của type này.
   *
   * Đặt ở template chứ không ở từng variant vì variant là để đổi CÂU CHỮ, không
   * phải đổi hình: gắn ảnh vào variant thì mỗi lần biên tập thêm một wording lại
   * phải nhớ đính ảnh, và một variant quên ảnh sẽ ra một noti trông khác hẳn
   * những variant còn lại của cùng một loại.
   *
   * `null` = noti chỉ có chữ, đúng như mọi template trước khi có field này.
   */
  @Prop({ type: String, default: null })
  imageUrl?: string | null;

  /**
   * `{ en: { title, body }, vi: {...} }`. Mixed because the locale set is
   * content, not schema: the sheet ships 8 (vi/en/ko/zh/ja/id/ms/fil) while the
   * app itself only has 5, and a locale with no entry falls back to `en`.
   *
   * Bodies may contain `{user_name}`, `{course_name}`, `{topic_name}` and
   * `{quote}`. The older `{lesson_name}` still renders — it now resolves to the
   * course name — so copy saved before the rename keeps working.
   *
   * Superseded by [variants] and kept in step with its first entry. The
   * dispatcher only reads this field for a document written before variants
   * existed (see `variantsOf`), which is what lets a live template pick up the
   * feature without a migration — Mongo has no migration mechanism here, so
   * schema changes have to be additive.
   */
  @Prop({ type: SchemaTypes.Mixed, default: {} })
  copies: Record<string, INotificationCopy>;

  /**
   * Every wording this notification may go out with. One entry behaves exactly
   * like the single [copies] map did; several make the dispatcher rotate them
   * (random, avoiding the last three days for that user).
   */
  @Prop({ type: SchemaTypes.Mixed, default: [] })
  variants: INotificationVariant[];

  /**
   * Where variant keys come from: never decremented, not even when a variant is
   * deleted.
   *
   * A recycled key would be read as the deleted wording's history, so the
   * cooldown could suppress a brand-new sentence for three days. Counting live
   * entries instead would recycle keys on every delete-then-add.
   */
  @Prop({ type: Number, default: 0 })
  variantSeq: number;

  /**
   * Send this type only to members of ANY of these segments. Empty = everybody,
   * which is what every template did before targeting existed.
   *
   * Ids, not embedded criteria: a segment is edited in one place and every
   * surface that targets it (Home banner, Home popup, this) follows along.
   */
  @Prop({ type: [String], default: [] })
  segmentIds: string[];
}

export const NotificationTemplateSchema =
  SchemaFactory.createForClass(NotificationTemplate);

/** The locale every user falls back to — including the sheet's id/ms/fil. */
export const NOTIFICATION_FALLBACK_LOCALE = 'en';
