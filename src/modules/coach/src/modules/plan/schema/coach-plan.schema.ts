import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose';
import { SchemaTypes } from 'mongoose';

import { AbstractDocument } from '@base/database/mongodb/abstract.schema';

import {
  CoachPlanAnswer,
  CoachPlanSource,
  CoachPlanStatus,
  CoachReminderDays,
} from '../enum/plan.enum';
import { ICoachPlan, ICoachPlanReminder } from '../interface/plan.interface';

@Schema({ collection: 'coach_plans' })
export class CoachPlan extends AbstractDocument implements ICoachPlan {
  @Prop({ required: true })
  userId: string;

  @Prop({ type: String, required: true })
  context: string;

  @Prop({ type: String, required: true })
  action: string;

  @Prop({
    type: String,
    enum: CoachPlanStatus,
    default: CoachPlanStatus.PENDING,
  })
  status: CoachPlanStatus;

  @Prop({ type: String, enum: CoachPlanSource, required: true })
  source: CoachPlanSource;

  @Prop({ type: String, default: null })
  habitId?: string | null;

  @Prop({ type: Date, default: null })
  lastAskedAt?: Date | null;

  @Prop({ type: String, enum: [...Object.values(CoachPlanAnswer), null], default: null })
  lastAnswer?: CoachPlanAnswer | null;

  @Prop({ type: Number, default: 0, min: 0 })
  consecutiveNoOccasion: number;

  @Prop({
    type: SchemaTypes.Mixed,
    default: (): ICoachPlanReminder => ({
      enabled: false,
      hour: 20,
      minute: 0,
      days: CoachReminderDays.DAILY,
    }),
  })
  reminder: ICoachPlanReminder;

  @Prop({ type: Date, default: null })
  lastNotifiedAt?: Date | null;
}

export const CoachPlanSchema = SchemaFactory.createForClass(CoachPlan);

// The ③A read: "this reader's pending plans, oldest-asked first".
CoachPlanSchema.index({ userId: 1, status: 1, lastAskedAt: 1 });

// The ④ dispatcher read, which runs every minute for every hour of the day and
// must not collection-scan. Status leads because it eliminates the most rows.
CoachPlanSchema.index({ status: 1, 'reminder.enabled': 1, 'reminder.hour': 1 });
