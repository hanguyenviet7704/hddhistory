import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose';

import { AbstractDocument } from '@base/database/mongodb/abstract.schema';

import {
  CommunityReactionKind,
  CommunityTargetType,
} from '../../../enum/community.enum';
import { ICommunityReaction } from '../interface/community-reaction.interface';

@Schema({ collection: 'community_reactions' })
export class CommunityReaction
  extends AbstractDocument
  implements ICommunityReaction
{
  @Prop({ type: String, enum: CommunityTargetType, required: true })
  targetType: CommunityTargetType;

  @Prop({ required: true })
  targetId: string;

  @Prop({ required: true })
  userId: string;

  @Prop({ type: String, enum: CommunityReactionKind, required: true })
  kind: CommunityReactionKind;
}

export const CommunityReactionSchema =
  SchemaFactory.createForClass(CommunityReaction);

// A double tap must not count twice — the write is an upsert against this key.
CommunityReactionSchema.index(
  { targetType: 1, targetId: 1, userId: 1, kind: 1 },
  { unique: true },
);
// "Which of these did I like?" for one page of the feed.
CommunityReactionSchema.index({ userId: 1, kind: 1, targetId: 1 });
// The saved-posts list, newest save first.
CommunityReactionSchema.index({ userId: 1, kind: 1, createdAt: -1 });
