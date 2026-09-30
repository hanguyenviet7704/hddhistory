import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose';

import { AbstractDocument } from '@base/database/mongodb/abstract.schema';

import { CommunityTargetType } from '../../../enum/community.enum';
import { ICommunityHiddenItem } from '../interface/community-reaction.interface';

// "Ẩn nội dung này" from the post menu. This is a per-reader preference, NOT
// moderation: the post stays visible to everyone else and never reaches the
// report queue on its own.
@Schema({ collection: 'community_hidden_items' })
export class CommunityHiddenItem
  extends AbstractDocument
  implements ICommunityHiddenItem
{
  @Prop({ required: true })
  userId: string;

  @Prop({ type: String, enum: CommunityTargetType, required: true })
  targetType: CommunityTargetType;

  @Prop({ required: true })
  targetId: string;
}

export const CommunityHiddenItemSchema =
  SchemaFactory.createForClass(CommunityHiddenItem);

CommunityHiddenItemSchema.index(
  { userId: 1, targetType: 1, targetId: 1 },
  { unique: true },
);
