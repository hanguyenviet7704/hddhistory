import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose';
import { SchemaTypes } from 'mongoose';

import { AbstractDocument } from '@base/database/mongodb/abstract.schema';
import { ITranslation } from '@utils/interface/common.interface';

import { IOnboardingBranch } from '../interface/onboarding-taxonomy.interface';

@Schema({ collection: 'onboarding_branches' })
export class OnboardingBranch
  extends AbstractDocument
  implements IOnboardingBranch
{
  @Prop({ required: true, trim: true, uppercase: true })
  code: string;

  @Prop({ type: SchemaTypes.Mixed, default: {} })
  label: ITranslation;

  @Prop({ type: SchemaTypes.Mixed, default: {} })
  subtitle: ITranslation;

  @Prop({ default: '' })
  iconUrl: string;

  @Prop({ default: '' })
  imageUrl: string;

  @Prop({ default: 0 })
  order: number;

  @Prop({ default: true })
  isSelectable: boolean;

  @Prop({ type: String, default: null })
  categoryId: string | null;

  @Prop({ default: true })
  isActive: boolean;
}

export const OnboardingBranchSchema =
  SchemaFactory.createForClass(OnboardingBranch);
OnboardingBranchSchema.index({ code: 1 }, { unique: true });
OnboardingBranchSchema.index({ isActive: 1, order: 1 });
