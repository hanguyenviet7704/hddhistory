import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose';
import { SchemaTypes, Types } from 'mongoose';

import { AbstractDocument } from '@base/database/mongodb/abstract.schema';
import {
  ExerciseResult,
  ExerciseResultSchema,
} from 'src/modules/courses/src/modules/progress/src/modules/user-progress/schema/user-progress.schema';

import { HabitCheckinMethod } from '../../user-habit/enum/user-habit.enum';
import { IHabitPracticeAttempt } from '../interface/habit-practice.interface';

/**
 * One completed practice session, with per-question detail.
 *
 * Separate from `habit_checkins` on purpose: that collection is unique on
 * `{ userHabitId, date }` — one row per habit per day, which is what the streak
 * is computed from. Attempts have no such limit, so a user can practise twice in
 * a day (or redo a quiz) without either overwriting the day's diary note or
 * disturbing `computeStreakFromDoneDates`. The check-in row keeps only the
 * denormalised `method`/`mood`/`score` summary so the Habit tab and the admin
 * list render without joining this collection.
 *
 * `exercisesResult` reuses `ExerciseResultSchema` from user-progress rather than
 * defining a parallel answer shape. It already models every answer type the
 * design's quiz deck uses — single choice, multiple choice, and both drag-drop
 * forms (text gap and arrange-sequence) — plus record, which the deck does not
 * use yet. A second shape would only be a second thing to keep in sync.
 */
@Schema({ collection: 'habit_practice_attempts' })
export class HabitPracticeAttempt
  extends AbstractDocument
  implements IHabitPracticeAttempt
{
  @Prop({ type: SchemaTypes.ObjectId, required: true })
  userHabitId: Types.ObjectId;

  // Denormalised from the user_habit so admin reads and per-habit analytics
  // don't have to resolve the adoption row first.
  @Prop({ type: SchemaTypes.ObjectId, required: true })
  habitId: Types.ObjectId;

  // Date-only (UTC midnight) via normalizeDateOnly, matching habit_checkins.date
  // so an attempt can be lined up with the check-in it filed.
  @Prop({ type: Date, required: true })
  date: Date;

  @Prop({ type: String, enum: HabitCheckinMethod, required: true })
  method: HabitCheckinMethod;

  // Null for a journal attempt, which has no authored content.
  @Prop({ type: SchemaTypes.ObjectId, default: null })
  learningItemId?: Types.ObjectId | null;

  @Prop({ type: [ExerciseResultSchema], default: [] })
  exercisesResult: ExerciseResult[];

  @Prop({ type: Number, min: 0 })
  score?: number;

  @Prop({ type: Number, min: 0 })
  total?: number;

  // Journal mood, 1..3 — see habit-checkin.schema.ts for why it is never 0.
  @Prop({ type: Number, min: 1, max: 3 })
  mood?: number;

  @Prop({ type: Date, default: Date.now })
  completedAt: Date;
}

export const HabitPracticeAttemptSchema = SchemaFactory.createForClass(
  HabitPracticeAttempt,
);

// The admin detail read and any "recent attempts" view.
HabitPracticeAttemptSchema.index({ userHabitId: 1, date: -1 });

// Per-habit analytics across users ("which practice do people fail?").
HabitPracticeAttemptSchema.index({ habitId: 1, date: -1 });
