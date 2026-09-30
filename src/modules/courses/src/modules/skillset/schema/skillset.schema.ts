import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose';
import { SchemaTypes } from 'mongoose';

import { AbstractDocument } from '@base/database/mongodb/abstract.schema';
import { ITranslation } from '@utils/interface/common.interface';

import {
  SkillsetOnboardingIntroduce,
  SkillsetStatus,
} from '../enum/skillset.enum';
import { ISkillset } from '../interface/skillset.interface';

@Schema()
export class Skillset extends AbstractDocument implements ISkillset {
  @Prop({ type: Number, default: 0 })
  index: number;

  @Prop({ type: SchemaTypes.Mixed })
  title: ITranslation;

  @Prop({ type: SchemaTypes.Mixed })
  description?: ITranslation;

  @Prop({ enum: SkillsetStatus })
  status: SkillsetStatus;

  @Prop()
  image: string;

  @Prop({ type: String, enum: SkillsetOnboardingIntroduce })
  onboardingIntroduce?: SkillsetOnboardingIntroduce;

  courses?: any[];
}

export const SkillsetSchema = SchemaFactory.createForClass(Skillset);

SkillsetSchema.index({ status: 1, index: 1 });
