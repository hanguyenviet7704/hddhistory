import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose';
import { SchemaTypes } from 'mongoose';

import { AbstractDocument } from '@base/database/mongodb/abstract.schema';
import { ITranslation } from '@utils/interface/common.interface';

import { IncompleteFeedbackReason } from '../enum/user-feedback.enum';
import {
  IUserFeedback,
  IUserFeedbackComplete,
  IUserFeedbackIncomplete,
} from '../interface/user-feedback.interface';

@Schema({ _id: false })
export class UserFeedbackComplete implements IUserFeedbackComplete {
  @Prop({ required: true })
  courseId: string;

  @Prop({ type: SchemaTypes.Mixed })
  courseTitle?: ITranslation;

  @Prop({ required: true })
  lessonId: string;

  @Prop({ type: SchemaTypes.Mixed })
  lessonTitle?: ITranslation;

  @Prop()
  keypointId?: string;

  @Prop({ type: SchemaTypes.Mixed })
  keypointTitle?: ITranslation;

  @Prop({ type: Number, min: 1, max: 5 })
  overallRating: number;

  @Prop({ type: Number, min: 1, max: 5 })
  contentRating: number;

  @Prop({ type: Number, min: 1, max: 5 })
  experienceRating: number;

  @Prop()
  comment?: string;

  @Prop({ type: Date, default: Date.now })
  submittedAt?: Date;
}
export const UserFeedbackCompleteSchema =
  SchemaFactory.createForClass(UserFeedbackComplete);

@Schema({ _id: false })
export class UserFeedbackIncomplete implements IUserFeedbackIncomplete {
  @Prop({ required: true })
  courseId: string;

  @Prop({ type: SchemaTypes.Mixed })
  courseTitle?: ITranslation;

  @Prop({ required: true })
  lessonId: string;

  @Prop({ type: SchemaTypes.Mixed })
  lessonTitle?: ITranslation;

  @Prop()
  keypointId?: string;

  @Prop({ type: SchemaTypes.Mixed })
  keypointTitle?: ITranslation;

  @Prop({ type: [String], enum: IncompleteFeedbackReason, default: [] })
  reasons?: IncompleteFeedbackReason[];

  @Prop()
  comment?: string;

  @Prop({ type: Date, default: Date.now })
  submittedAt?: Date;
}
export const UserFeedbackIncompleteSchema = SchemaFactory.createForClass(
  UserFeedbackIncomplete,
);

@Schema({ collection: 'user_feedback' })
export class UserFeedback extends AbstractDocument implements IUserFeedback {
  @Prop({ required: true })
  userId: string;

  @Prop({ type: UserFeedbackCompleteSchema })
  roleplayComplete?: UserFeedbackComplete;

  @Prop({ type: UserFeedbackIncompleteSchema })
  roleplayIncomplete?: UserFeedbackIncomplete;

  @Prop({ type: UserFeedbackCompleteSchema })
  keypointComplete?: UserFeedbackComplete;

  @Prop({ type: UserFeedbackIncompleteSchema })
  keypointIncomplete?: UserFeedbackIncomplete;
}

export const UserFeedbackSchema = SchemaFactory.createForClass(UserFeedback);

UserFeedbackSchema.index({ userId: 1 }, { unique: true });
