import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose';

import { AbstractDocument } from '@base/database/mongodb/abstract.schema';

/**
 * One (segment, day) → member count, written by the nightly snapshot cron.
 *
 * Membership is computed live from the `users` collection, so history cannot
 * be reconstructed after the fact — the growth chart the admin sees starts the
 * day the segment was created, and a day the cron missed stays a gap rather
 * than being back-filled with a guess.
 */
@Schema({ collection: 'segment_snapshots' })
export class SegmentSnapshot extends AbstractDocument {
  @Prop({ type: String, required: true, index: true })
  segmentId: string;

  /** UTC calendar day, `YYYY-MM-DD` — same keying as the promo stats. */
  @Prop({ type: String, required: true })
  date: string;

  @Prop({ type: Number, default: 0 })
  count: number;
}

export const SegmentSnapshotSchema =
  SchemaFactory.createForClass(SegmentSnapshot);

// One row per segment per day; the cron's write is an idempotent upsert.
SegmentSnapshotSchema.index({ segmentId: 1, date: 1 }, { unique: true });
