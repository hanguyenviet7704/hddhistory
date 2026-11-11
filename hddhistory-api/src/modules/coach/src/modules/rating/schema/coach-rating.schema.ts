import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose';

import { AbstractDocument } from '@base/database/mongodb/abstract.schema';

import {
  CoachRatingChip,
  CoachSessionKind,
  CoachRatingSource,
  CoachRatingThumb,
} from '../enum/rating.enum';
import { ICoachRating } from '../interface/rating.interface';

@Schema({ collection: 'coach_ratings' })
export class CoachRating extends AbstractDocument implements ICoachRating {
  @Prop({ required: true })
  userId: string;

  @Prop({ type: String, required: true })
  sessionId: string;

  /**
   * Null on every row written since the 👍/👎 toast was removed (2026-09-14).
   * Required would reject the sheet that replaced it; the chips carry the
   * sentiment now.
   */
  @Prop({ type: String, enum: [...Object.values(CoachRatingThumb), null], default: null })
  thumb?: CoachRatingThumb | null;

  @Prop({ type: [String], enum: CoachRatingChip, default: [] })
  chips: CoachRatingChip[];

  @Prop({ type: String, default: null })
  note?: string | null;

  @Prop({ type: Boolean, default: false })
  needsReview: boolean;

  /**
   * Rows written before the exit sheet existed carry no `source` at all, so the
   * default has to be the older meaning — everything already in the collection
   * IS a rating-toast row.
   */
  @Prop({ type: String, enum: CoachRatingSource, default: CoachRatingSource.RATING })
  source: CoachRatingSource;

  /**
   * Which chip set this answer came from. Null on rows older than 2026-09-14 —
   * admin shows those as "Không rõ loại" rather than guessing one.
   */
  @Prop({
    type: String,
    enum: [...Object.values(CoachSessionKind), null],
    default: null,
  })
  sessionKind?: CoachSessionKind | null;
}

export const CoachRatingSchema = SchemaFactory.createForClass(CoachRating);

CoachRatingSchema.index({ userId: 1, createdAt: -1 });
// The admin queue reads this alone, so it leads the index.
CoachRatingSchema.index({ needsReview: 1, createdAt: -1 });
