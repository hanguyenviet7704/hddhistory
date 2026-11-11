import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose';

import { AbstractDocument } from '@base/database/mongodb/abstract.schema';

import { CommunityContentStatus } from '../../../enum/community.enum';
import { ICommunityChatRoom } from '../interface/community-chat.interface';

@Schema({ collection: 'community_chat_rooms' })
export class CommunityChatRoom
  extends AbstractDocument
  implements ICommunityChatRoom
{
  @Prop({ required: true })
  name: string;

  @Prop({ required: true, unique: true })
  slug: string;

  @Prop({ default: true })
  isOfficial: boolean;

  @Prop({
    type: String,
    enum: CommunityContentStatus,
    default: CommunityContentStatus.VISIBLE,
  })
  status: CommunityContentStatus;

  @Prop({ default: 0 })
  messageCount: number;

  /**
   * IANA zone the room's bot schedule is read in.
   *
   * Per room rather than one global clock: a Japanese room's evening is not a
   * Vietnamese room's evening, and a slot written as 21:00 has to mean 21:00
   * where the people in that room live.
   */
  @Prop({ default: 'Asia/Ho_Chi_Minh' })
  timezone: string;
}

export const CommunityChatRoomSchema =
  SchemaFactory.createForClass(CommunityChatRoom);

CommunityChatRoomSchema.index({ status: 1, createdAt: 1 });
