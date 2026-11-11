import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose';

import { AbstractDocument } from '@base/database/mongodb/abstract.schema';

import { CoachBoostKind } from '../enum/boost.enum';
import { ICoachBoostHistory } from '../interface/boost.interface';

@Schema({ collection: 'coach_boost_history' })
export class CoachBoostHistory
  extends AbstractDocument
  implements ICoachBoostHistory
{
  @Prop({ type: String, required: true })
  userId: string;

  @Prop({ type: String, enum: CoachBoostKind, required: true })
  kind: CoachBoostKind;

  @Prop({ type: String, default: null })
  refId?: string | null;

  @Prop({ type: Date, default: null })
  lastShownAt?: Date | null;

  @Prop({ type: Number, default: 0, min: 0 })
  skipStreak: number;

  @Prop({ type: Date, default: null })
  mutedUntil?: Date | null;

  @Prop({ type: Number, default: 0, min: 0 })
  eligibleSince: number;
}

export const CoachBoostHistorySchema =
  SchemaFactory.createForClass(CoachBoostHistory);

// One row per (reader, add-on, thing) — the upsert target. `refId` is null for
// everything but the course card, and null participates in the key.
CoachBoostHistorySchema.index({ userId: 1, kind: 1, refId: 1 }, { unique: true });
