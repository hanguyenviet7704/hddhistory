import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose';
import { SchemaTypes } from 'mongoose';

import { AbstractDocument } from '@base/database/mongodb/abstract.schema';

import {
  IOnboardingScenarioBranching,
  IOnboardingScenarioScene,
} from '../interface/onboarding-scenario-branching.interface';

@Schema({ collection: 'onboarding_scenario_branching' })
export class OnboardingScenarioBranching
  extends AbstractDocument
  implements IOnboardingScenarioBranching
{
  @Prop()
  entrySceneId: string;

  @Prop({ type: SchemaTypes.Array })
  scenes: IOnboardingScenarioScene[];
}

export const OnboardingScenarioBranchingSchema = SchemaFactory.createForClass(
  OnboardingScenarioBranching,
);
