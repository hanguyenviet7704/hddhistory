import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose';

import { AbstractDocument } from '@base/database/mongodb/abstract.schema';

import { ICommunityThreadMute } from '../interface/community-reaction.interface';

/**
 * "I turned the bell off on this thread, and I meant it."
 *
 * A separate row rather than a flag on the SAVE reaction, because unfollowing
 * DELETES that reaction — there is nothing left to hang a flag on. And it has
 * to be remembered at all now that two things write a follow on the reader's
 * behalf: commenting auto-follows, and the new-comment fan-out reaches anyone
 * who has ever written in the thread. Without this row, both would quietly
 * undo the tap that switched them off.
 *
 * Only ever written by an explicit tap on the bell — auto-follow reads it and
 * never touches it, so the reader's own choice is the only thing in here.
 */
@Schema({ collection: 'community_thread_mutes' })
export class CommunityThreadMute
  extends AbstractDocument
  implements ICommunityThreadMute
{
  @Prop({ required: true })
  userId: string;

  @Prop({ required: true })
  postId: string;
}

export const CommunityThreadMuteSchema =
  SchemaFactory.createForClass(CommunityThreadMute);

// One row per reader per thread — the write is an upsert against this key.
CommunityThreadMuteSchema.index({ userId: 1, postId: 1 }, { unique: true });
// "Who muted this thread?", asked once per new comment.
CommunityThreadMuteSchema.index({ postId: 1 });
