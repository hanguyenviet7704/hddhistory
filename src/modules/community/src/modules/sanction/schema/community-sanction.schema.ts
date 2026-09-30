import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose';

import { AbstractDocument } from '@base/database/mongodb/abstract.schema';

import { ICommunitySanction } from '../interface/community-sanction.interface';

// A row per sanction rather than a flag on the user, so the violation history
// survives being lifted — that history is what a moderator needs before
// deciding whether a second offence is a 7-day or a permanent mute.
@Schema({ collection: 'community_sanctions' })
export class CommunitySanction
  extends AbstractDocument
  implements ICommunitySanction
{
  @Prop({ required: true })
  userId: string;

  @Prop()
  mutedUntil?: Date;

  @Prop({ required: true })
  reason: string;

  @Prop({ required: true })
  createdByUserId: string;

  @Prop()
  revokedAt?: Date;

  @Prop()
  revokedByUserId?: string;
}

export const CommunitySanctionSchema =
  SchemaFactory.createForClass(CommunitySanction);

// Lookup on every write attempt: the active sanction for one user.
CommunitySanctionSchema.index({ userId: 1, revokedAt: 1, mutedUntil: -1 });
CommunitySanctionSchema.index({ createdAt: -1 });
