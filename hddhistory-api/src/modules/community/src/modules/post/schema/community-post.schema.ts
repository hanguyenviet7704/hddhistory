import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose';
import { SchemaTypes } from 'mongoose';

import { AbstractDocument } from '@base/database/mongodb/abstract.schema';
import { ITranslation } from '@utils/interface/common.interface';

import {
  CommunityAuthorType,
  CommunityContentStatus,
  CommunityPostType,
} from '../../../enum/community.enum';
import {
  ICommunityAttachedCard,
  ICommunityWeeklyWindow,
} from '../../../interface/community.interface';
import { ICommunityPost } from '../interface/community-post.interface';

@Schema({ collection: 'community_posts' })
export class CommunityPost extends AbstractDocument implements ICommunityPost {
  @Prop({
    type: String,
    enum: CommunityPostType,
    default: CommunityPostType.POST,
  })
  type: CommunityPostType;

  @Prop({
    type: String,
    enum: CommunityAuthorType,
    default: CommunityAuthorType.USER,
  })
  authorType: CommunityAuthorType;

  @Prop({ required: true })
  authorId: string;

  // Optional: the composer lets a reader post without picking a group.
  @Prop()
  topicId?: string;

  @Prop()
  locale?: string;

  // The headline above the story. Empty on posts written before the composer
  // grew a title field, and on weekly questions, which carry `title` instead.
  @Prop({ default: '' })
  subject: string;

  @Prop({ default: '' })
  body: string;

  @Prop({ type: [String], default: [] })
  images: string[];

  // Opens the shared-roadmap screen (S-08) when tapped.
  @Prop()
  attachedCourseId?: string;

  // A saved keypoint card, snapshotted at compose time. See
  // ICommunityAttachedCard for why it is copied and not referenced.
  @Prop({ type: SchemaTypes.Mixed })
  attachedCard?: ICommunityAttachedCard;

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

  @Prop({ default: false })
  isPinned: boolean;

  @Prop()
  pinnedAt?: Date;

  @Prop({ default: false })
  commentsLocked: boolean;

  @Prop({ default: 0 })
  likeCount: number;

  @Prop({ default: 0 })
  commentCount: number;

  @Prop({ default: 0 })
  saveCount: number;

  @Prop({ default: 0 })
  reportCount: number;

  // Bumped by a new comment. Kept separate from updatedAt, which also moves on
  // a moderation edit.
  @Prop({ type: Date, default: Date.now })
  lastActivityAt: Date;

  // WEEKLY_QUESTION only.
  @Prop({ type: SchemaTypes.Mixed })
  weekly?: ICommunityWeeklyWindow;

  @Prop({ type: SchemaTypes.Mixed })
  title?: ITranslation;

  @Prop({ type: SchemaTypes.Mixed })
  note?: ITranslation;

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

export const CommunityPostSchema = SchemaFactory.createForClass(CommunityPost);

// Main feed: visible posts in the reader's language, newest first.
CommunityPostSchema.index({ status: 1, locale: 1, createdAt: -1 });
// One topic's feed.
CommunityPostSchema.index({ topicId: 1, status: 1, locale: 1, createdAt: -1 });
// A reader's own posts (profile / "my posts").
CommunityPostSchema.index({ authorId: 1, createdAt: -1 });
// The open weekly question.
CommunityPostSchema.index({ type: 1, 'weekly.endsAt': -1 });
// Moderation queue, worst first.
CommunityPostSchema.index({ status: 1, reportCount: -1 });
