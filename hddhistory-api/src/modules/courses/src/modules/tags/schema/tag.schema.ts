import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose';
import { SchemaTypes } from 'mongoose';

import { AbstractDocument } from '@base/database/mongodb/abstract.schema';
import { ITranslation } from '@utils/interface/common.interface';

import { ITag } from '../interface/tag.interface';

@Schema()
export class Tag extends AbstractDocument implements ITag {
  @Prop({ type: SchemaTypes.Mixed })
  title: ITranslation;

  @Prop()
  color: string;

  @Prop()
  url: string;
}

export const TagSchema = SchemaFactory.createForClass(Tag);
