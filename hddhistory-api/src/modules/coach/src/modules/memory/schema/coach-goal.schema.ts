import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose';

import { AbstractDocument } from '@base/database/mongodb/abstract.schema';

import { CoachGoalStatus, ICoachGoal } from '../interface/memory.interface';

/** What the reader is working toward, in their words, and how far along. */
@Schema({ collection: 'coach_goals', timestamps: true })
export class CoachGoal extends AbstractDocument implements ICoachGoal {
  @Prop({ type: String, required: true, index: true })
  userId: string;

  @Prop({ type: String, required: true })
  goal: string;

  @Prop({ type: String, enum: CoachGoalStatus, default: CoachGoalStatus.ACTIVE })
  status: CoachGoalStatus;

  @Prop({ type: Number, default: 0 })
  priority: number;

  @Prop({ type: Number, default: 0 })
  progress: number;

  @Prop({ type: [String], default: [] })
  sourceSessionIds: string[];
}

export const CoachGoalSchema = SchemaFactory.createForClass(CoachGoal);
CoachGoalSchema.index({ userId: 1, status: 1, updatedAt: -1 });
