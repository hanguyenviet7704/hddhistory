import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose';

import { AbstractDocument } from '@base/database/mongodb/abstract.schema';

import {
  CommunityAuthorType,
  CommunityContentStatus,
} from '../../../enum/community.enum';
import { ICommunityChatMessage } from '../interface/community-chat.interface';

@Schema({ collection: 'community_chat_messages' })
export class CommunityChatMessage
  extends AbstractDocument
  implements ICommunityChatMessage
{
  @Prop({ required: true })
  roomId: string;

  @Prop({ required: true })
  authorId: string;

  @Prop({
    type: String,
    enum: CommunityAuthorType,
    default: CommunityAuthorType.USER,
  })
  authorType: CommunityAuthorType;

  @Prop({ default: false })
  isModerator: boolean;

  @Prop({ required: true })
  body: string;

  @Prop({
    type: String,
    enum: CommunityContentStatus,
    default: CommunityContentStatus.VISIBLE,
  })
  status: CommunityContentStatus;

  @Prop()
  hiddenReason?: string;

  @Prop()
  moderatedBy?: string;

  @Prop()
  moderatedAt?: Date;

  @Prop({ default: 0 })
  likeCount: number;

  @Prop({ default: 0 })
  reportCount: number;

  /**
   * When an admin pinned this, absent when it is not pinned.
   *
   * A timestamp rather than a boolean because the pin bar draws the MOST
   * RECENT pin and the sheet lists them newest first — a flag would mean
   * sorting by the message's own date, which is a different order as soon as
   * somebody pins an old line.
   */
  @Prop()
  pinnedAt?: Date;

  @Prop()
  pinnedBy?: string;

  /**
   * The message this one answers, if any.
   *
   * Flat: a reply points at one line and the room stays one stream. The quoted
   * text is NOT copied here — it is read back through this id, so editing or
   * hiding the original reaches every reply to it.
   */
  @Prop()
  replyToId?: string;

  /**
   * The bot run that wrote this, absent on everything a human wrote.
   *
   * Never serialised to the app: a persona is meant to read as an ordinary
   * member. It is here so one run can be taken back in a single query, and so
   * moderation and any later counting can tell the two apart.
   */
  @Prop()
  botRunId?: string;
}

export const CommunityChatMessageSchema =
  SchemaFactory.createForClass(CommunityChatMessage);

// The room's transcript, newest first — the only read path that matters.
CommunityChatMessageSchema.index({ roomId: 1, status: 1, createdAt: -1 });
// Unread counting past a member's lastReadAt.
CommunityChatMessageSchema.index({ roomId: 1, createdAt: -1, authorId: 1 });
// The flood ceiling: this author's lines inside the last minute. The roomId
// index above cannot serve it — authorId is its third key.
CommunityChatMessageSchema.index({ authorId: 1, createdAt: -1 });
// Moderation queue.
CommunityChatMessageSchema.index({ status: 1, reportCount: -1 });
// Replies to one line, for the "N câu trả lời" style lookups a room may grow.
CommunityChatMessageSchema.index(
  { replyToId: 1 },
  { partialFilterExpression: { replyToId: { $exists: true } } },
);
// The room's pins, newest pin first. Partial so the index holds only the
// handful of pinned rows rather than a null entry for every line ever written.
CommunityChatMessageSchema.index(
  { roomId: 1, pinnedAt: -1 },
  { partialFilterExpression: { pinnedAt: { $exists: true } } },
);
