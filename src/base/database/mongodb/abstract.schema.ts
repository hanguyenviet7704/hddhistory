import { Prop, Schema } from '@nestjs/mongoose';
import { SchemaTypes, Types } from 'mongoose';

import { IUserMeta } from './abstract.interface';

@Schema()
export class AbstractDocument {
  @Prop({ type: SchemaTypes.ObjectId, default: () => new Types.ObjectId() })
  _id: Types.ObjectId;

  @Prop({ type: Date, default: Date.now })
  createdAt: Date;

  @Prop({ type: Date, default: Date.now })
  updatedAt: Date;

  @Prop({ type: SchemaTypes.Mixed })
  createdBy: IUserMeta;

  @Prop({ type: Object })
  updatedBy: IUserMeta;
}
