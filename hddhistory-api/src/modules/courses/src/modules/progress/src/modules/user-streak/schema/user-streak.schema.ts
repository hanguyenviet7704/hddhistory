import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose';

import { AbstractDocument } from '@base/database/mongodb/abstract.schema';

import { IUserStreak } from '../interface/user-streak.interface';
import { STREAK_WEEK_DAYS, normalizeWeekStudy } from '../user-streak.helper';

@Schema({ collection: 'user_streaks' })
export class UserStreak extends AbstractDocument implements IUserStreak {
  @Prop({ required: true, unique: true })
  userId: string;

  // Monday of current streak week (Mon-Sun).
  // Used to detect week rollover and reset weekStudy/studyTime.
  @Prop({ required: true, type: Date })
  weekStartDate: Date;

  // Fixed 7-day completion flags for current week only.
  // Index map: Mon=0 ... Sun=6.
  @Prop({
    type: [Boolean],
    default: () => normalizeWeekStudy(),
    validate: [(days: boolean[]) => days?.length === STREAK_WEEK_DAYS, 'weekStudy must have 7 days'],
  })
  weekStudy: boolean[];

  // Total weekly study time in minutes.
  // Increased by estimateCompleTimeNumber on each completion event.
  @Prop({ type: Number, default: 0, min: 0 })
  studyTime: number;

  // Active streak count across weeks (not limited by 7 days).
  @Prop({ type: Number, default: 0, min: 0 })
  currentStreak: number;

  // Highest streak observed in user history.
  // Never decreases when current streak drops/reset.
  @Prop({ type: Number, default: 0, min: 0 })
  bestStreak: number;
}

export const UserStreakSchema = SchemaFactory.createForClass(UserStreak);

UserStreakSchema.index({ userId: 1 }, { unique: true });
