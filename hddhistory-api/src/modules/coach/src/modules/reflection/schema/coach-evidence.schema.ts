import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose';

import { AbstractDocument } from '@base/database/mongodb/abstract.schema';

import { ICoachEvidence } from '../interface/reflection.interface';

@Schema({ collection: 'coach_evidence' })
export class CoachEvidence extends AbstractDocument implements ICoachEvidence {
  @Prop({ required: true })
  userId: string;

  @Prop({ type: String, required: true })
  planId: string;

  @Prop({ type: String, default: null })
  habitId?: string | null;

  @Prop({ type: String, required: true })
  content: string;
}

export const CoachEvidenceSchema = SchemaFactory.createForClass(CoachEvidence);

CoachEvidenceSchema.index({ userId: 1, createdAt: -1 });
CoachEvidenceSchema.index({ planId: 1 });
