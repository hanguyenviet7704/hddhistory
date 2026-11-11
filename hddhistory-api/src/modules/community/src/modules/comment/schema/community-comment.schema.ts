import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose';

import { AbstractDocument } from '@base/database/mongodb/abstract.schema';

import {
  CommunityAuthorType,
  CommunityContentStatus,
} from '../../../enum/community.enum';
import { ICommunityComment } from '../interface/community-comment.interface';

@Schema({ collection: 'community_comments' })
export class CommunityComment
  extends AbstractDocument
  implements ICommunityComment
{
  @Prop({ required: true })
  postId: string;

  @Prop()
  parentId?: string;

  @Prop()
  replyToUserId?: string;

  @Prop({ required: true })
  authorId: string;

  @Prop({
    type: String,
    enum: CommunityAuthorType,
    default: CommunityAuthorType.USER,
  })
  authorType: CommunityAuthorType;

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
  replyCount: number;

  @Prop({ default: 0 })
  reportCount: number;

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

export const CommunityCommentSchema =
  SchemaFactory.createForClass(CommunityComment);

// One post's comment thread.
CommunityCommentSchema.index({ postId: 1, parentId: 1, status: 1, createdAt: -1 });
CommunityCommentSchema.index({ authorId: 1, createdAt: -1 });
// Moderation queue.
CommunityCommentSchema.index({ status: 1, reportCount: -1 });
