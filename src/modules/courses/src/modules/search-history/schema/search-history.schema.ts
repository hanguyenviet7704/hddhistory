import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose';
import { Document } from 'mongoose';

import { AbstractDocument } from '@base/database/mongodb/abstract.schema';

export type SearchHistoryDocument = SearchHistory & Document;

@Schema({ timestamps: true, collection: 'search_histories' })
export class SearchHistory extends AbstractDocument {
  @Prop({ required: true, index: true })
  userId: string;

  @Prop({ required: true })
  query: string;
}

export const SearchHistorySchema = SchemaFactory.createForClass(SearchHistory);

SearchHistorySchema.index({ userId: 1, query: 1 }, { unique: true });
SearchHistorySchema.index({ userId: 1, createdAt: -1 });
