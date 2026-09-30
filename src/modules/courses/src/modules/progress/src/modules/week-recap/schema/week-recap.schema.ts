import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose';
import { SchemaTypes } from 'mongoose';

import { AbstractDocument } from '@base/database/mongodb/abstract.schema';

import {
  IWeekRecap,
  IWeekRecapCourse,
  IWeekRecapCoach,
  IWeekRecapDay,
  IWeekRecapHabit,
  IWeekRecapLesson,
  IWeekRecapStats,
} from '../interface/week-recap.interface';

/**
 * One finished week, gift-wrapped — the document behind the scrapbook poster.
 *
 * A SNAPSHOT, not a view. The numbers are computed once when the week closes
 * and never recomputed: a poster the learner has already shared to a story must
 * not quietly disagree with itself later because a keypoint was re-graded or a
 * course was unpublished.
 *
 * Titles are stored as the raw translation objects rather than resolved
 * strings, the same way every other content document here does it — one
 * document serves all five locales, and a learner who switches language should
 * see their own history in the new one.
 */
@Schema({ collection: 'week_recaps', timestamps: true })
export class WeekRecap extends AbstractDocument implements IWeekRecap {
  @Prop({ type: String, required: true, index: true })
  userId: string;

  /**
   * The instant the learner's LOCAL Monday 00:00 was, in UTC.
   *
   * Local, because "last week" is the learner's week: deriving it from the
   * server's Monday would hand a Vietnamese learner a recap that starts on
   * Sunday morning. Stored as the resolved instant so the unique index below
   * has one unambiguous value to key on.
   */
  @Prop({ type: Date, required: true })
  weekStart: Date;

  @Prop({ type: Date, required: true })
  weekEnd: Date;

  /**
   * The offset the week boundaries were resolved with, kept for the record.
   *
   * A learner who flies to another timezone does NOT get last week rebuilt
   * around the new offset — the week already happened, and re-cutting it would
   * move keypoints between the poster they saw and the one they see next.
   */
  @Prop({ type: Number, required: true })
  tzOffset: number;

  /**
   * "Tuần 01" — the learner's own count, not the ISO week.
   *
   * Assigned once at generation and never recomputed. Someone who skips a week
   * goes from `Tuần 02` to `Tuần 03` rather than jumping a number: the poster
   * is the Nth wrap they earned, not a position in the calendar.
   */
  @Prop({ type: Number, required: true })
  weekNumber: number;

  /**
   * Whether the week had anything in it at all.
   *
   * A `false` row exists so a quiet week is not re-aggregated on every app
   * open. It is filtered out of every read: no recap is the product decision
   * for a week nobody showed up for, and an empty poster would be worse than
   * none.
   */
  @Prop({ type: Boolean, required: true, default: false })
  hasActivity: boolean;

  @Prop({ type: SchemaTypes.Mixed, required: true })
  stats: IWeekRecapStats;

  /** Exactly seven entries, Monday first. */
  @Prop({ type: [SchemaTypes.Mixed], default: [] })
  days: IWeekRecapDay[];

  /**
   * ⑤ the AI Coach's four blocks, frozen into the snapshot like everything else
   * on this poster.
   *
   * Computed at cut time rather than on read for the same reason the stats are:
   * a poster somebody has already shared must not change its mind later. Null —
   * and absent on every document written before Coach shipped — means the
   * poster draws nothing here.
   */
  @Prop({ type: SchemaTypes.Mixed, default: null })
  coach?: IWeekRecapCoach | null;

  @Prop({ type: [SchemaTypes.Mixed], default: [] })
  lessons: IWeekRecapLesson[];

  @Prop({ type: [SchemaTypes.Mixed], default: [] })
  habits: IWeekRecapHabit[];

  @Prop({ type: SchemaTypes.Mixed })
  favouriteCourse?: IWeekRecapCourse;

  /** Set when the learner opened the poster. Silences the popup for good. */
  @Prop({ type: Date })
  viewedAt?: Date;

  /**
   * Set by "Để sau".
   *
   * Kept apart from [viewedAt] on purpose: both silence the popup, but only one
   * of them means the learner actually saw their week, and the difference is
   * what any later "did this feature land" question will be asked of.
   */
  @Prop({ type: Date })
  dismissedAt?: Date;

  @Prop({ type: Date, required: true, default: Date.now })
  generatedAt: Date;
}

export const WeekRecapSchema = SchemaFactory.createForClass(WeekRecap);

// The pair that makes generation idempotent: two app opens racing each other
// both upsert the same week, and the loser gets a duplicate-key error instead
// of writing a second poster for it.
WeekRecapSchema.index({ userId: 1, weekStart: 1 }, { unique: true });

// The Sổ tay listing: this learner's real recaps, newest first.
WeekRecapSchema.index({ userId: 1, hasActivity: 1, weekStart: -1 });
