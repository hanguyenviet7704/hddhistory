import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose';
import { SchemaTypes } from 'mongoose';

import { AbstractDocument } from '@base/database/mongodb/abstract.schema';
import { ITranslation } from '@utils/interface/common.interface';

import { ICommunityTopicStats } from '../../../interface/community.interface';
import { ICommunityTopic } from '../interface/community-topic.interface';

@Schema({ collection: 'community_topics' })
export class CommunityTopic
  extends AbstractDocument
  implements ICommunityTopic
{
  @Prop({ type: SchemaTypes.Mixed, required: true })
  name: ITranslation;

  @Prop({ type: SchemaTypes.Mixed, default: {} })
  description: ITranslation;

  @Prop({ required: true })
  slug: string;

  @Prop()
  imageUrl?: string;

  @Prop({ default: 0 })
  sortOrder: number;

  @Prop({ default: true })
  isActive: boolean;

  // Keyed by locale: { vi: { followers, postsThisWeek }, ... }. Mixed rather
  // than a nested schema so a new locale needs no migration.
  @Prop({ type: SchemaTypes.Mixed, default: {} })
  stats: ICommunityTopicStats;
}

export const CommunityTopicSchema =
  SchemaFactory.createForClass(CommunityTopic);

CommunityTopicSchema.index({ slug: 1 }, { unique: true });
CommunityTopicSchema.index({ isActive: 1, sortOrder: 1 });
