import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose';
import { SchemaTypes } from 'mongoose';

import { AbstractDocument } from '@base/database/mongodb/abstract.schema';
import { ILablel } from '@utils/interface/user.interface';

import {
  IMotivation,
  IOnboarding,
  IOnboardingCopy,
  IOnboardingIntro,
  IOnboardingPath,
} from '../interface/onboarding.interface';

@Schema()
export class Onboarding extends AbstractDocument implements IOnboarding {
  @Prop({ type: SchemaTypes.Array })
  intro: IOnboardingIntro[];

  @Prop({ type: SchemaTypes.Array })
  age: ILablel[];

  @Prop({ type: SchemaTypes.Array })
  gender: ILablel[];

  @Prop({ type: SchemaTypes.Array })
  skillsetWantToMaster: ILablel[];

  @Prop({ type: SchemaTypes.Array })
  learningGoal: ILablel[];

  @Prop({ type: SchemaTypes.Array })
  learningStruggles: ILablel[];

  @Prop({ type: SchemaTypes.Array })
  comfortableLearningTime: ILablel[];

  @Prop({ type: SchemaTypes.Array })
  dailyLearningGoal: ILablel[];

  @Prop({ type: SchemaTypes.Mixed })
  welcome: IMotivation;

  @Prop({ type: SchemaTypes.Mixed })
  motivationOne: IMotivation;

  @Prop({ type: SchemaTypes.Mixed })
  motivationTwo: IMotivation;

  @Prop({ type: SchemaTypes.Mixed })
  motivationThree: IMotivation;

  @Prop({ type: SchemaTypes.Mixed })
  loading: IMotivation;

  @Prop({ type: SchemaTypes.Array })
  paths: IOnboardingPath[];

  @Prop({ type: SchemaTypes.Array })
  copy: IOnboardingCopy[];
}

export const OnboardingSchema = SchemaFactory.createForClass(Onboarding);
