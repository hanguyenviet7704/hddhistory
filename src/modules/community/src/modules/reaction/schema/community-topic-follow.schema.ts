import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose';

import { AbstractDocument } from '@base/database/mongodb/abstract.schema';

import { ICommunityTopicFollow } from '../interface/community-reaction.interface';

@Schema({ collection: 'community_topic_follows' })
export class CommunityTopicFollow
  extends AbstractDocument
  implements ICommunityTopicFollow
{
  @Prop({ required: true })
  topicId: string;

  @Prop({ required: true })
  userId: string;

  @Prop({ required: true })
  locale: string;
}

export const CommunityTopicFollowSchema =
  SchemaFactory.createForClass(CommunityTopicFollow);

CommunityTopicFollowSchema.index({ topicId: 1, userId: 1 }, { unique: true });
CommunityTopicFollowSchema.index({ userId: 1 });
