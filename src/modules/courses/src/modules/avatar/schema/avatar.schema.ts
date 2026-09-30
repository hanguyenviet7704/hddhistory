import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose';

import { AbstractDocument } from '@base/database/mongodb/abstract.schema';

import { IAvatar } from '../interface/avatar.interface';

@Schema()
export class Avatar extends AbstractDocument implements IAvatar {
  @Prop()
  name: string;

  @Prop()
  url: string;
}

export const AvatarSchema = SchemaFactory.createForClass(Avatar);
