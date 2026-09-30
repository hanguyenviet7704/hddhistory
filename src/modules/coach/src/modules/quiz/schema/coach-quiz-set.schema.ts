import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose';
import { SchemaTypes } from 'mongoose';

import { AbstractDocument } from '@base/database/mongodb/abstract.schema';

import { ICoachQuizQuestion, ICoachQuizSet } from '../interface/quiz.interface';

/**
 * A generated quiz about one keypoint, in one language. Written once, read
 * many times, and never thrown away: generating costs a model call, and the
 * questions are about published teaching material that does not change often.
 */
@Schema({ collection: 'coach_quiz_sets', timestamps: true })
export class CoachQuizSet extends AbstractDocument implements ICoachQuizSet {
  @Prop({ type: String, required: true, index: true })
  keypointId: string;

  @Prop({ type: String, required: true })
  locale: string;

  @Prop({ type: SchemaTypes.Mixed, default: [] })
  questions: ICoachQuizQuestion[];

  @Prop({ type: Number, default: 0 })
  servedCount?: number;
}

export const CoachQuizSetSchema = SchemaFactory.createForClass(CoachQuizSet);

// "Which sets exist for this keypoint in this language, newest first?" — the
// one read behind every quiz.
CoachQuizSetSchema.index({ keypointId: 1, locale: 1, createdAt: -1 });
