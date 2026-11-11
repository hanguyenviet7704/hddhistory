import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose';

import { AbstractDocument } from '@base/database/mongodb/abstract.schema';

import { CommunityRoomSuggestionStatus } from '../../../enum/community.enum';
import { ICommunityRoomSuggestion } from '../interface/community-room-suggestion.interface';

/**
 * "Không thấy phòng bạn cần?" — a reader asking for a room that does not exist.
 *
 * Deliberately NOT a `community_topics` row with a draft flag: a suggestion has
 * no locale-keyed name, no stats and no sort order, and letting an unopened
 * room sit in the topics collection means every topic query has to remember to
 * filter it out.
 */
@Schema({ collection: 'community_room_suggestions' })
export class CommunityRoomSuggestion
  extends AbstractDocument
  implements ICommunityRoomSuggestion
{
  @Prop({ required: true })
  name: string;

  @Prop({ default: '' })
  description: string;

  @Prop({ required: true })
  authorId: string;

  @Prop({ required: true })
  locale: string;

  @Prop({
    type: String,
    enum: CommunityRoomSuggestionStatus,
    default: CommunityRoomSuggestionStatus.PENDING,
  })
  status: CommunityRoomSuggestionStatus;

  // Who backed it. Held as an array rather than a reactions collection because
  // the only questions ever asked are "how many" and "did I" — and an array
  // answers both with no join. A suggestion is reviewed long before this grows
  // large.
  @Prop({ type: [String], default: [] })
  voterIds: string[];

  // Kept in step with voterIds.length by an aggregation-pipeline update, so it
  // cannot drift, and can be indexed for the most-wanted sort (an array's
  // length cannot).
  @Prop({ default: 1 })
  voteCount: number;

  @Prop()
  topicId?: string;

  @Prop()
  reviewedBy?: string;

  @Prop()
  reviewedAt?: Date;

  @Prop()
  reviewNote?: string;
}

export const CommunityRoomSuggestionSchema = SchemaFactory.createForClass(
  CommunityRoomSuggestion,
);

// The reader-facing list: what else has been asked for in my language, most
// wanted first.
CommunityRoomSuggestionSchema.index({ locale: 1, status: 1, voteCount: -1 });
// The moderation queue.
CommunityRoomSuggestionSchema.index({ status: 1, createdAt: -1 });
// "Did I already ask for this?" — the duplicate check.
CommunityRoomSuggestionSchema.index({ authorId: 1, createdAt: -1 });
