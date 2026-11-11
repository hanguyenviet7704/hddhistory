import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose';

import { AbstractDocument } from '@base/database/mongodb/abstract.schema';

import { IOnboardingAnswer } from '../interface/onboarding-answer.interface';

@Schema({ collection: 'onboarding_answers' })
export class OnboardingAnswer
  extends AbstractDocument
  implements IOnboardingAnswer
{
  @Prop({ required: true })
  userId: string;

  @Prop({ type: [String], default: [] })
  branchCodes: string[];

  @Prop({ type: [String], default: [] })
  packageCodes: string[];

  @Prop({ type: String, default: null })
  desireCode: string | null;

  @Prop({ default: false })
  reminderEnabled: boolean;

  @Prop({ type: String, default: null })
  reminderTime: string | null;

  @Prop({ type: [String], default: [] })
  recommendedCourseIds: string[];

  @Prop({ type: String, default: null })
  chosenCourseId: string | null;

  @Prop({ type: String, default: null })
  ageKey: string | null;

  @Prop({ type: Date, default: null })
  completedAt: Date | null;
}
export const OnboardingAnswerSchema =
  SchemaFactory.createForClass(OnboardingAnswer);
OnboardingAnswerSchema.index({ userId: 1 }, { unique: true });
