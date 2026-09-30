import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose';

import { AbstractDocument } from '@base/database/mongodb/abstract.schema';

import { ICoachProgress } from '../interface/memory.interface';

/** Something the reader DID toward a goal, and how it went. */
@Schema({ collection: 'coach_progress', timestamps: true })
export class CoachProgress extends AbstractDocument implements ICoachProgress {
  @Prop({ type: String, required: true, index: true })
  userId: string;

  @Prop({ type: String, required: true })
  sessionId: string;

  @Prop({ type: String, required: true })
  goal: string;

  @Prop({ type: String, required: true })
  action: string;

  @Prop({ type: String, required: true })
  result: string;
}

export const CoachProgressSchema = SchemaFactory.createForClass(CoachProgress);
CoachProgressSchema.index({ userId: 1, createdAt: -1 });
