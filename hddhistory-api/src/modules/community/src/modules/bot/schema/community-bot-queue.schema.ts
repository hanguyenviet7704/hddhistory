import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose';

import { AbstractDocument } from '@base/database/mongodb/abstract.schema';

import {
  CommunityBotKind,
  CommunityBotQueueStatus,
} from '../enum/community-bot.enum';

/**
 * One line a persona is going to write, and when.
 *
 * Generation and publishing are deliberately separate steps. A burst arrives
 * from the model all at once; a room where six lines land in the same second
 * reads as a machine no matter how good the words are. Holding them here also
 * means admin can read a burst BEFORE anybody else does, and edit or drop a
 * line without a review workflow existing.
 */
@Schema({ collection: 'community_bot_queue' })
export class CommunityBotQueue extends AbstractDocument {
  /** One generation = one runId, across every line it produced. */
  @Prop({ required: true })
  runId: string;

  /**
   * What this line belongs to, down to the minute of the local day.
   *
   * Unique, and that is the whole concurrency story: a tick that runs twice, or
   * two containers ticking at the same second, collide on the second insert and
   * give up. No distributed lock, no leader election.
   */
  @Prop({ required: true, unique: true })
  slotKey: string;

  @Prop({ type: String, required: true, enum: CommunityBotKind })
  kind: CommunityBotKind;

  @Prop({ required: true })
  personaUserId: string;

  @Prop()
  roomId?: string;

  @Prop()
  postId?: string;

  @Prop()
  topicId?: string;

  @Prop()
  subject?: string;

  @Prop({ required: true })
  body: string;

  /** A message in the same room this line answers, when it answers one. */
  @Prop()
  replyToId?: string;

  @Prop({ required: true })
  locale: string;

  @Prop({ type: Date, required: true })
  dueAt: Date;

  @Prop({
    type: String,
    enum: CommunityBotQueueStatus,
    default: CommunityBotQueueStatus.PENDING,
  })
  status: CommunityBotQueueStatus;

  @Prop()
  error?: string;

  /** The message/post/comment this became, once it was published. */
  @Prop()
  resultId?: string;

  @Prop()
  publishedAt?: Date;
}

export const CommunityBotQueueSchema =
  SchemaFactory.createForClass(CommunityBotQueue);

// The cron's only read: what is due now.
CommunityBotQueueSchema.index({ status: 1, dueAt: 1 });
// One burst, for the panel's "review this run" and for taking it back.
CommunityBotQueueSchema.index({ runId: 1 });
// The panel's list.
CommunityBotQueueSchema.index({ createdAt: -1 });
// Today's output per kind, for the daily ceilings.
CommunityBotQueueSchema.index({ kind: 1, status: 1, createdAt: -1 });
