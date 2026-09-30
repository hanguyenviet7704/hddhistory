import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose';

import { AbstractDocument } from '@base/database/mongodb/abstract.schema';

import { COACH_MOOD_MAX, COACH_MOOD_MIN } from '../../../shared/coach.constant';
import { DayLogMoment } from '../enum/day-log.enum';
import { IUserDayLog } from '../interface/day-log.interface';

@Schema({ collection: 'user_day_logs' })
export class UserDayLog extends AbstractDocument implements IUserDayLog {
  @Prop({ required: true })
  userId: string;

  @Prop({ type: Date, required: true })
  date: Date;

  @Prop({ type: String, enum: DayLogMoment, required: true })
  moment: DayLogMoment;

  // 1..3, never 0-based — see COACH_MOOD_MIN.
  @Prop({ type: Number, min: COACH_MOOD_MIN, max: COACH_MOOD_MAX, default: null })
  mood?: number | null;

  @Prop({ type: String, default: null })
  note?: string | null;

  @Prop({ type: String, default: null })
  sessionId?: string | null;
}

export const UserDayLogSchema = SchemaFactory.createForClass(UserDayLog);

// Not unique: START is once a day, but END is once per SESSION and a reader can
// hold several conversations in a day. Uniqueness on START is enforced by the
// service asking "has today's start mood been recorded" before it prompts.
UserDayLogSchema.index({ userId: 1, date: -1, moment: 1 });
