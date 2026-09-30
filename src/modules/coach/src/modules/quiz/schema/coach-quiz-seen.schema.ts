import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose';

import { AbstractDocument } from '@base/database/mongodb/abstract.schema';

import { ICoachQuizSeen } from '../interface/quiz.interface';

/**
 * Which sets a reader has already been asked. Its own collection rather than an
 * array on the profile: it grows with every quiz taken, and the only question
 * ever asked of it is "which of THESE set ids has this reader seen?".
 */
@Schema({ collection: 'coach_quiz_seen', timestamps: true })
export class CoachQuizSeen extends AbstractDocument implements ICoachQuizSeen {
  @Prop({ type: String, required: true, index: true })
  userId: string;

  @Prop({ type: String, required: true })
  setId: string;

  @Prop({ type: String, required: true })
  keypointId: string;
}

export const CoachQuizSeenSchema = SchemaFactory.createForClass(CoachQuizSeen);

CoachQuizSeenSchema.index({ userId: 1, setId: 1 }, { unique: true });
