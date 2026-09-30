import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose';

import { AbstractDocument } from '@base/database/mongodb/abstract.schema';

import { CommunityAuthorType, CommunityNotificationType } from '../../../enum/community.enum';
import { ICommunityNotification } from '../interface/community-notification.interface';

@Schema({ collection: 'community_notifications' })
export class CommunityNotification
  extends AbstractDocument
  implements ICommunityNotification
{
  @Prop({ required: true })
  userId: string;

  @Prop({ type: String, enum: CommunityNotificationType, required: true })
  type: CommunityNotificationType;

  @Prop()
  actorId?: string;

  // Absent on every row written before this field existed — `list()` treats
  // that the same as USER, which is what those rows always were (official
  // replies did not carry this until now). See the interface doc for why it
  // has to be stored rather than re-derived at read time.
  @Prop({ type: String, enum: CommunityAuthorType })
  actorType?: CommunityAuthorType;

  @Prop()
  postId?: string;

  @Prop()
  commentId?: string;

  // MESSAGE_IN_ROOM only. The SLUG travels beside the id because the app names
  // a room by slug (`CommunityChatRoute(room:)`) — the push deeplink and the
  // in-app row both need it, and looking it up per row would be a join.
  @Prop()
  roomId?: string;

  @Prop()
  roomSlug?: string;

  // How many people did this, counting `actorId` as the most recent one. Only
  // LIKE_ON_POST goes above 1: likes collapse to a single row per post so a
  // post that does well is one line — "Thu Hà và 12 người khác" — instead of
  // thirteen. Everything else stays a row per event.
  @Prop({ default: 1 })
  actorCount: number;

  @Prop({ default: false })
  isRead: boolean;
}

export const CommunityNotificationSchema =
  SchemaFactory.createForClass(CommunityNotification);

CommunityNotificationSchema.index({ userId: 1, createdAt: -1 });
CommunityNotificationSchema.index({ userId: 1, isRead: 1 });
