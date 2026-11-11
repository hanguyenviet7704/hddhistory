import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose';

import { AbstractDocument } from '@base/database/mongodb/abstract.schema';

import {
  InAppSurveyEmoji,
  InAppSurveyEmojiSchema,
  InAppSurveyOption,
  InAppSurveyOptionSchema,
  InAppSurveyQuestion,
  InAppSurveyQuestionSchema,
} from './in-app-survey-config.schema';
import { InAppSurveyClosedQuestionType } from '../enum/in-app-survey.enum';
import {
  IInAppSurveyResponse,
  IInAppSurveyResponseBranch,
  IInAppSurveyQuestion,
  IInAppSurveyOption,
  IInAppSurveyUserSnapshot,
} from '../interface/in-app-survey.interface';

@Schema({ _id: false })
export class InAppSurveyUserSnapshot implements IInAppSurveyUserSnapshot {
  @Prop()
  name?: string;

  @Prop()
  email?: string;

  @Prop()
  avatar?: string;
}
export const InAppSurveyUserSnapshotSchema = SchemaFactory.createForClass(
  InAppSurveyUserSnapshot,
);

@Schema({ _id: false })
export class InAppSurveyResponseClosedQuestion extends InAppSurveyQuestion {
  @Prop({
    enum: InAppSurveyClosedQuestionType,
    required: true,
    default: InAppSurveyClosedQuestionType.MULTIPLE_CHOICE,
  })
  type: InAppSurveyClosedQuestionType;
}
export const InAppSurveyResponseClosedQuestionSchema =
  SchemaFactory.createForClass(InAppSurveyResponseClosedQuestion);

@Schema({ _id: false })
export class InAppSurveyResponseBranch implements IInAppSurveyResponseBranch {
  @Prop({ type: InAppSurveyEmojiSchema, required: true })
  emoji: InAppSurveyEmoji;

  @Prop({ type: InAppSurveyResponseClosedQuestionSchema, required: true })
  closedQuestion: InAppSurveyResponseClosedQuestion;

  @Prop({ type: InAppSurveyQuestionSchema, required: true })
  openQuestion: IInAppSurveyQuestion;
}
export const InAppSurveyResponseBranchSchema = SchemaFactory.createForClass(
  InAppSurveyResponseBranch,
);

@Schema({ collection: 'in_app_survey_responses' })
export class InAppSurveyResponse
  extends AbstractDocument
  implements IInAppSurveyResponse
{
  @Prop({ required: true })
  userId: string;

  @Prop({ type: InAppSurveyUserSnapshotSchema })
  userSnapshot?: InAppSurveyUserSnapshot;

  @Prop({ required: true })
  branchId: string;

  @Prop({ type: Number })
  branchIndex?: number;

  @Prop()
  branchName?: string;

  @Prop({ type: Number })
  ratingScore?: number;

  @Prop({ type: InAppSurveyQuestionSchema, required: true })
  introQuestion: InAppSurveyQuestion;

  @Prop({ type: InAppSurveyResponseBranchSchema, required: true })
  branch: InAppSurveyResponseBranch;

  @Prop({ type: [InAppSurveyOptionSchema], default: [] })
  selectedOptions: IInAppSurveyOption[];

  @Prop()
  feedback?: string;

  @Prop({ type: Date, default: Date.now })
  submittedAt?: Date;

  @Prop({ type: Date, default: Date.now })
  completedAt?: Date;
}

export const InAppSurveyResponseSchema =
  SchemaFactory.createForClass(InAppSurveyResponse);

InAppSurveyResponseSchema.index({ userId: 1, submittedAt: -1 });
InAppSurveyResponseSchema.index({ submittedAt: -1 });
InAppSurveyResponseSchema.index({ branchId: 1, submittedAt: -1 });
InAppSurveyResponseSchema.index({ ratingScore: 1, submittedAt: -1 });
export type InAppSurveyResponseQuestion = InAppSurveyQuestion;
export type InAppSurveyResponseOption = InAppSurveyOption;
