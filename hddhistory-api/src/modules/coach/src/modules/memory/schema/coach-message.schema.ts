import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose';

import { AbstractDocument } from '@base/database/mongodb/abstract.schema';

import { ICoachMessage } from '../interface/memory.interface';

/**
 * RAW — every line of every Coach conversation, kept for good.
 *
 * `coach_sessions` holds state and expires in 48h; this does not. It is the
 * source of truth the memory layer is extracted FROM, and what lets a memory
 * be audited ("did the model read this right?") or re-extracted with a better
 * model later. "Không được chỉ lưu summary rồi xoá raw."
 */
@Schema({ collection: 'coach_messages', timestamps: true })
export class CoachMessage extends AbstractDocument implements ICoachMessage {
  @Prop({ type: String, required: true, index: true })
  userId: string;

  @Prop({ type: String, required: true, index: true })
  sessionId: string;

  @Prop({ type: String, required: true })
  entry: string;

  @Prop({ type: String, required: true, enum: ['user', 'coach'] })
  role: 'user' | 'coach';

  @Prop({ type: String, required: true })
  step: string;

  @Prop({ type: String, required: true })
  content: string;
}

export const CoachMessageSchema = SchemaFactory.createForClass(CoachMessage);
CoachMessageSchema.index({ userId: 1, createdAt: -1 });
// Cô đọng tăng dần đọc theo (phiên, mốc thời gian): `sessionId` đơn lẻ phải
// quét cả phiên rồi mới lọc theo `createdAt`.
CoachMessageSchema.index({ sessionId: 1, createdAt: 1 });
