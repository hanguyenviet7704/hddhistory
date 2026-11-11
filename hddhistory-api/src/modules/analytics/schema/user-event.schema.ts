import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose';
import { SchemaTypes, Types } from 'mongoose';

import { AbstractDocument } from '@base/database/mongodb/abstract.schema';

import { UserEventKind } from '../enum/analytics.enum';
import { IUserEvent } from '../interface/user-event.interface';

// One document per fired tracking event, mirrored from the app's
// CompositeTrackingService. Write-heavy, read by user, and self-cleaning via a
// TTL index — hence Mongo rather than MySQL, and `params` stays a free-form bag
// so a new event never needs a schema change.
@Schema({ collection: 'user_events' })
export class UserEvent extends AbstractDocument implements IUserEvent {
  @Prop({ type: SchemaTypes.ObjectId, required: true })
  userId: Types.ObjectId;

  @Prop({ required: true })
  deviceId: string;

  @Prop({ required: true })
  sessionId: string;

  @Prop({ required: true })
  name: string;

  @Prop({ enum: UserEventKind, default: UserEventKind.EVENT })
  kind: UserEventKind;

  @Prop({ type: SchemaTypes.Mixed, default: {} })
  params: Record<string, any>;

  // When the app fired it — the axis the timeline is ordered by. Kept separate
  // from serverTs because a queued batch can arrive minutes (or a restart) late.
  @Prop({ type: Date, required: true })
  clientTs: Date;

  @Prop({ type: Date, default: Date.now })
  serverTs: Date;

  @Prop()
  appEnv: string;

  @Prop()
  appVersion: string;

  @Prop()
  platform: string;
}

export const UserEventSchema = SchemaFactory.createForClass(UserEvent);

// Admin's main query: one user's events over a date range, newest first.
UserEventSchema.index({ userId: 1, clientTs: -1 });
// Reading the events inside one session, oldest first.
UserEventSchema.index({ userId: 1, sessionId: 1, clientTs: 1 });
// The product dashboard reads across ALL users for a period, which none of the
// userId-first indexes above can serve — without these two it is a collection
// scan per panel.
UserEventSchema.index({ appEnv: 1, clientTs: -1 });
// Funnel and learning-milestone queries filter by event name inside the range.
UserEventSchema.index({ appEnv: 1, name: 1, clientTs: -1 });
// Self-cleaning after 90 days. No cron, no manual purge.
UserEventSchema.index({ serverTs: 1 }, { expireAfterSeconds: 90 * 24 * 3600 });
