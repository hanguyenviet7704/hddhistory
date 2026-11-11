import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose';
import { SchemaTypes, Types } from 'mongoose';

import { AbstractDocument } from '@base/database/mongodb/abstract.schema';
import { ITranslation } from '@utils/interface/common.interface';

import { ReanchorReasonStatus } from '../enum/reanchor-reason.enum';
import { IReanchorReason } from '../interface/reanchor-reason.interface';

// Admin-managed, per-course "why did you pause?" re-anchor prompts (§9.1).
@Schema({ collection: 'reanchor_reasons' })
export class ReanchorReason
  extends AbstractDocument
  implements IReanchorReason
{
  @Prop({ type: SchemaTypes.ObjectId, required: true })
  courseId: Types.ObjectId;

  @Prop({ type: SchemaTypes.Mixed, required: true })
  reason: ITranslation;

  @Prop({ type: Number, default: 0 })
  order: number;

  @Prop({
    type: String,
    enum: ReanchorReasonStatus,
    default: ReanchorReasonStatus.DRAFT,
  })
  status: ReanchorReasonStatus;
}

export const ReanchorReasonSchema =
  SchemaFactory.createForClass(ReanchorReason);

ReanchorReasonSchema.index({ courseId: 1, status: 1, order: 1 });
