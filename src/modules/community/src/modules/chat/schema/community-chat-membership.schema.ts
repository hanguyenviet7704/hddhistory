import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose';

import { AbstractDocument } from '@base/database/mongodb/abstract.schema';

import { ICommunityChatMembership } from '../interface/community-chat.interface';

@Schema({ collection: 'community_chat_memberships' })
export class CommunityChatMembership
  extends AbstractDocument
  implements ICommunityChatMembership
{
  @Prop({ required: true })
  roomId: string;

  @Prop({ required: true })
  userId: string;

  @Prop({ type: Date, default: Date.now })
  lastSeenAt: Date;

  @Prop({ type: Date })
  lastReadAt?: Date;
}

export const CommunityChatMembershipSchema =
  SchemaFactory.createForClass(CommunityChatMembership);

// One row per member per room, and the presence window query.
CommunityChatMembershipSchema.index({ roomId: 1, userId: 1 }, { unique: true });
CommunityChatMembershipSchema.index({ roomId: 1, lastSeenAt: -1 });
