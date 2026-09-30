import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose';
import { SchemaTypes } from 'mongoose';

import { AbstractDocument } from '@base/database/mongodb/abstract.schema';
import { ITranslation } from '@utils/interface/common.interface';

import { IQuote } from '../interface/quote.interface';

@Schema()
export class Quote extends AbstractDocument implements IQuote {
  @Prop({ type: SchemaTypes.Mixed })
  content: ITranslation;

  @Prop()
  backgroundColor: string;

  @Prop()
  textColor: string;
}

export const QuoteSchema = SchemaFactory.createForClass(Quote);
