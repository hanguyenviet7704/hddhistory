import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose';
import { SchemaTypes } from 'mongoose';

import { AbstractDocument } from '@base/database/mongodb/abstract.schema';
import { ITranslation } from '@utils/interface/common.interface';

import {
  CategoryOnboardingIntroduce,
  CategoryStatus,
} from '../enum/category.enum';
import { ICategory } from '../interface/category.interface';

@Schema()
export class Category extends AbstractDocument implements ICategory {
  @Prop({ type: Number, default: 0 })
  index: number;

  @Prop({ type: SchemaTypes.Mixed })
  title: ITranslation;

  @Prop({ type: SchemaTypes.Mixed })
  description?: ITranslation;

  @Prop({ enum: CategoryStatus })
  status: CategoryStatus;

  @Prop()
  image: string;

  @Prop({ type: String, enum: CategoryOnboardingIntroduce })
  onboardingIntroduce?: CategoryOnboardingIntroduce;

  courses?: any[];
}

export const CategorySchema = SchemaFactory.createForClass(Category);

CategorySchema.index({ status: 1, index: 1 });
