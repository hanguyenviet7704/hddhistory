import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose';
import { Document } from 'mongoose';

import { AbstractDocument } from '@base/database/mongodb/abstract.schema';

export type SpacedReviewItemDocument = SpacedReviewItem & Document;

/**
 * Lịch ôn của MỘT keypoint cho MỘT người. Sinh ra lười: lần đầu người đó mở
 * "Ôn tập hôm nay", mọi keypoint họ đã qua (đọc từ `user_progress`) mà chưa có
 * dòng ở đây sẽ được thêm vào — không phải chạm vào luồng ghi tiến độ, và người
 * học từ trước khi có tính năng cũng có lịch ngay.
 */
@Schema({ timestamps: true, collection: 'spaced_review_items' })
export class SpacedReviewItem extends AbstractDocument {
  @Prop({ required: true })
  userId: string;

  @Prop({ required: true })
  keypointId: string;

  @Prop()
  lessonId: string;

  @Prop()
  courseId: string;

  /** Chỉ số trong `REVIEW_INTERVAL_DAYS` đã sinh ra `dueAt` hiện tại. */
  @Prop({ type: Number, default: 0 })
  step: number;

  @Prop({ type: Date, required: true })
  dueAt: Date;

  @Prop({ type: Date })
  lastReviewedAt?: Date;

  @Prop({ type: Number, default: 0 })
  reviewCount: number;

  /** Số lần ôn sai — keypoint hay quên. */
  @Prop({ type: Number, default: 0 })
  lapses: number;
}

export const SpacedReviewItemSchema =
  SchemaFactory.createForClass(SpacedReviewItem);

// Một lịch cho mỗi (người, keypoint) — đồng bộ lười chạy lại không nhân đôi.
SpacedReviewItemSchema.index({ userId: 1, keypointId: 1 }, { unique: true });
// Hàng đợi "đến hạn": của người này, hạn sớm nhất trước.
SpacedReviewItemSchema.index({ userId: 1, dueAt: 1 });
