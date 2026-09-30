import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose';

import { AbstractDocument } from '@base/database/mongodb/abstract.schema';

import { CoachMetricKind } from '../enum/coach-metric.enum';
import { ICoachMetric } from '../interface/coach-metric.interface';

@Schema({ collection: 'coach_metrics' })
export class CoachMetric extends AbstractDocument implements ICoachMetric {
  @Prop({ type: String, enum: CoachMetricKind, required: true })
  kind: CoachMetricKind;

  @Prop({ type: String, default: null })
  refId?: string | null;

  @Prop({ type: String, required: true })
  isoWeek: string;

  @Prop({ type: Number, default: 0, min: 0 })
  count: number;
}

export const CoachMetricSchema = SchemaFactory.createForClass(CoachMetric);

// One row per (kind, thing, week) — the upsert target.
CoachMetricSchema.index({ kind: 1, refId: 1, isoWeek: 1 }, { unique: true });
