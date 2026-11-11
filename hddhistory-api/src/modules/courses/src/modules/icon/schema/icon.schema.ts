import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose';

import { AbstractDocument } from '@base/database/mongodb/abstract.schema';

import { IIcon } from '../interface/icon.interface';

@Schema()
export class Icon extends AbstractDocument implements IIcon {
  @Prop()
  url: string;
}

export const IconSchema = SchemaFactory.createForClass(Icon);
