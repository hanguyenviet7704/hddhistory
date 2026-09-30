import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose';
import { SchemaTypes } from 'mongoose';

import { AbstractDocument } from '@base/database/mongodb/abstract.schema';
import { ITranslation } from '@utils/interface/common.interface';

import { InAppSurveyClosedQuestionType } from '../enum/in-app-survey.enum';
import {
  IInAppSurveyBranch,
  IInAppSurveyClosedQuestion,
  IInAppSurveyConfig,
  IInAppSurveyEmoji,
  IInAppSurveyOption,
  IInAppSurveyQuestion,
} from '../interface/in-app-survey.interface';

export const IN_APP_SURVEY_CONFIG_KEY = 'default';

@Schema({ _id: false })
export class InAppSurveyQuestion implements IInAppSurveyQuestion {
  @Prop({ type: SchemaTypes.Mixed, required: true })
  question: ITranslation;

  @Prop({ type: SchemaTypes.Mixed })
  guide?: ITranslation;
}
export const InAppSurveyQuestionSchema =
  SchemaFactory.createForClass(InAppSurveyQuestion);

@Schema({ _id: false })
export class InAppSurveyEmoji implements IInAppSurveyEmoji {
  @Prop()
  name?: string;

  @Prop({ required: true })
  darkUrl: string;

  @Prop()
  lightUrl?: string;
}
export const InAppSurveyEmojiSchema =
  SchemaFactory.createForClass(InAppSurveyEmoji);

@Schema({ _id: false })
export class InAppSurveyOption implements IInAppSurveyOption {
  @Prop({ required: true })
  id: string;

  @Prop({ required: true })
  icon: string;

  @Prop({ type: SchemaTypes.Mixed, required: true })
  value: ITranslation;
}
export const InAppSurveyOptionSchema =
  SchemaFactory.createForClass(InAppSurveyOption);

@Schema({ _id: false })
export class InAppSurveyClosedQuestion
  extends InAppSurveyQuestion
  implements IInAppSurveyClosedQuestion
{
  @Prop({
    enum: InAppSurveyClosedQuestionType,
    required: true,
    default: InAppSurveyClosedQuestionType.MULTIPLE_CHOICE,
  })
  type: InAppSurveyClosedQuestionType;

  @Prop({ type: [InAppSurveyOptionSchema], default: [] })
  options: InAppSurveyOption[];
}
export const InAppSurveyClosedQuestionSchema = SchemaFactory.createForClass(
  InAppSurveyClosedQuestion,
);

@Schema({ _id: false })
export class InAppSurveyBranch implements IInAppSurveyBranch {
  @Prop({ required: true })
  id: string;

  @Prop({ type: InAppSurveyEmojiSchema, required: true })
  emoji: InAppSurveyEmoji;

  @Prop({ type: InAppSurveyClosedQuestionSchema, required: true })
  closedQuestion: InAppSurveyClosedQuestion;

  @Prop({ type: InAppSurveyQuestionSchema, required: true })
  openQuestion: InAppSurveyQuestion;

  @Prop({ type: Number, required: true, default: 0 })
  index: number;

  @Prop({ type: Number })
  score?: number;
}
export const InAppSurveyBranchSchema =
  SchemaFactory.createForClass(InAppSurveyBranch);

@Schema({ collection: 'in_app_survey_configs' })
export class InAppSurveyConfig
  extends AbstractDocument
  implements IInAppSurveyConfig
{
  @Prop({
    required: true,
    default: IN_APP_SURVEY_CONFIG_KEY,
  })
  configKey: string;

  @Prop({ type: InAppSurveyQuestionSchema, required: true })
  introQuestion: InAppSurveyQuestion;

  @Prop({ type: [InAppSurveyBranchSchema], default: [] })
  branches: InAppSurveyBranch[];
}

export const InAppSurveyConfigSchema =
  SchemaFactory.createForClass(InAppSurveyConfig);

InAppSurveyConfigSchema.index({ configKey: 1 }, { unique: true });
