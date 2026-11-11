import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose';
import { SchemaTypes, Types } from 'mongoose';

import { AbstractDocument } from '@base/database/mongodb/abstract.schema';
import { ITranslation } from '@utils/interface/common.interface';

import { HabitPackLength, UserHabitState } from '../enum/user-habit.enum';
import { IUserHabit } from '../interface/user-habit.interface';

@Schema({ collection: 'user_habits' })
export class UserHabit extends AbstractDocument implements IUserHabit {
  @Prop({ required: true })
  userId: string;

  @Prop({ type: SchemaTypes.ObjectId, required: true })
  habitId: Types.ObjectId;

  @Prop({ type: String, enum: UserHabitState, default: UserHabitState.ACTIVE })
  state: UserHabitState;

  @Prop()
  reminderTime?: string;

  @Prop({ type: Number, enum: HabitPackLength, default: HabitPackLength.THREE_DAYS })
  packLength: HabitPackLength;

  @Prop({ type: Date, default: Date.now })
  startedAt: Date;

  @Prop({ type: Number, default: 0, min: 0 })
  currentStreak: number;

  @Prop({ type: Number, default: 0, min: 0 })
  bestStreak: number;

  @Prop({ type: Number, default: 0, min: 0 })
  totalCheckIns: number;

  @Prop({ type: Date, default: null })
  lastCheckInDate?: Date | null;

  // Where this habit was adopted from — powers grouping by course (§9.5) and
  // per-keypoint re-prompt gating (FR2.8). Optional: habits can also be
  // adopted straight from the library outside any keypoint/course context.
  @Prop({ type: SchemaTypes.ObjectId, default: null })
  sourceKeypointId?: Types.ObjectId | null;

  @Prop({ type: SchemaTypes.ObjectId, default: null })
  sourceCourseId?: Types.ObjectId | null;

  // The re-anchor reason the user picked for this course (§9.5): a snapshot of
  // their "why" at adopt time. `reanchorReasonId` is a soft reference to
  // reanchor_reasons; `reanchorReason` stores the text inline so the tracker
  // groups/labels clusters without a join and survives the library reason
  // being edited or removed.
  @Prop({ type: SchemaTypes.ObjectId, default: null })
  reanchorReasonId?: Types.ObjectId | null;

  @Prop({ type: SchemaTypes.Mixed, default: null })
  reanchorReason?: ITranslation | null;
}

export const UserHabitSchema = SchemaFactory.createForClass(UserHabit);

UserHabitSchema.index({ userId: 1, state: 1 });
