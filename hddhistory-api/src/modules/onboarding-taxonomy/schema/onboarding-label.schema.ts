import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose';
import { SchemaTypes } from 'mongoose';

import { AbstractDocument } from '@base/database/mongodb/abstract.schema';
import { ITranslation } from '@utils/interface/common.interface';

import { IOnboardingLabel } from '../interface/onboarding-taxonomy.interface';

@Schema({ collection: 'onboarding_labels' })
export class OnboardingLabel
  extends AbstractDocument
  implements IOnboardingLabel
{
  @Prop({ required: true, trim: true, uppercase: true })
  code: string;

  @Prop({ required: true, trim: true, uppercase: true })
  packageCode: string;

  @Prop({ type: SchemaTypes.Mixed, default: {} })
  label: ITranslation;

  @Prop({ default: 0 })
  order: number;
}

export const OnboardingLabelSchema =
  SchemaFactory.createForClass(OnboardingLabel);
OnboardingLabelSchema.index({ code: 1 }, { unique: true });
OnboardingLabelSchema.index({ packageCode: 1, order: 1 });
