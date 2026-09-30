import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose';
import { SchemaTypes } from 'mongoose';

import { AbstractDocument } from '@base/database/mongodb/abstract.schema';
import { ITranslation } from '@utils/interface/common.interface';

import { IOnboardingPackage } from '../interface/onboarding-taxonomy.interface';

@Schema({ collection: 'onboarding_packages' })
export class OnboardingPackage
  extends AbstractDocument
  implements IOnboardingPackage
{
  @Prop({ required: true, trim: true, uppercase: true })
  code: string;

  @Prop({ required: true, trim: true, uppercase: true })
  branchCode: string;

  @Prop({ type: SchemaTypes.Mixed, default: {} })
  problemLabel: ITranslation;

  @Prop({ type: SchemaTypes.Mixed, default: {} })
  desireLabel: ITranslation;

  @Prop({ default: 0 })
  order: number;

  @Prop({ default: true })
  isActive: boolean;
}

export const OnboardingPackageSchema =
  SchemaFactory.createForClass(OnboardingPackage);
OnboardingPackageSchema.index({ code: 1 }, { unique: true });
OnboardingPackageSchema.index({ branchCode: 1, order: 1 });
