import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose';

import { AbstractDocument } from '@base/database/mongodb/abstract.schema';

import {
  CoachStatementKind,
  ICoachProblemStatement,
} from '../interface/reflection.interface';

@Schema({ collection: 'coach_problem_statements' })
export class CoachProblemStatement
  extends AbstractDocument
  implements ICoachProblemStatement
{
  @Prop({ required: true })
  userId: string;

  @Prop({ type: String, required: true })
  sessionId: string;

  @Prop({ type: String, default: null })
  habitId?: string | null;

  @Prop({ type: String, required: true })
  content: string;

  @Prop({
    type: String,
    enum: CoachStatementKind,
    default: CoachStatementKind.PROBLEM_STATEMENT,
  })
  kind: CoachStatementKind;

  @Prop({ type: String, default: null })
  planId?: string | null;

  @Prop({ type: Number, default: null })
  draftProposedCount?: number;

  @Prop({ type: Number, default: null })
  draftKeptCount?: number;
}

export const CoachProblemStatementSchema = SchemaFactory.createForClass(
  CoachProblemStatement,
);

CoachProblemStatementSchema.index({ userId: 1, kind: 1, createdAt: -1 });
