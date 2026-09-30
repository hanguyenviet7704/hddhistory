import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose';
import { SchemaTypes, Types } from 'mongoose';

import { AbstractDocument } from '@base/database/mongodb/abstract.schema';

import { HabitCheckinMethod } from '../enum/user-habit.enum';
import { IHabitCheckin } from '../interface/user-habit.interface';

@Schema({ collection: 'habit_checkins' })
export class HabitCheckin extends AbstractDocument implements IHabitCheckin {
  @Prop({ type: SchemaTypes.ObjectId, required: true })
  userHabitId: Types.ObjectId;

  // Date-only (UTC midnight) — see user-habit.helper.ts normalizeDateOnly.
  @Prop({ type: Date, required: true })
  date: Date;

  @Prop({ type: Boolean, required: true })
  done: boolean;

  // Optional diary note for this day's check-in (Habit detail heatmap/diary).
  // Also carries the free text of a JOURNAL practice — same field, since a
  // journal entry *is* the day's diary note.
  @Prop({ type: String })
  note?: string;

  // Which route filed this check-in. Absent on rows written before practice
  // shipped; treat a missing value as TAP rather than backfilling.
  @Prop({ type: String, enum: HabitCheckinMethod })
  method?: HabitCheckinMethod;

  // Journal mood, a 3-level scale stored **1..3, never 0-based**: `mood: 0` is
  // falsy in both Dart and JS, so every `if (mood)` / `mood ?? fallback` in the
  // app and admin would silently drop the lowest level. The labels themselves
  // are slang l10n strings across 5 locales, so only the number lives here.
  @Prop({ type: Number, min: 1, max: 3 })
  mood?: number;

  // Correct-answer count of a quiz practice. The per-question detail lives in
  // `habit_practice_attempts`; this is the denormalised summary so the Habit
  // tab and the admin list render without a join.
  @Prop({ type: Number, min: 0 })
  score?: number;
}

export const HabitCheckinSchema = SchemaFactory.createForClass(HabitCheckin);

HabitCheckinSchema.index({ userHabitId: 1, date: 1 }, { unique: true });
