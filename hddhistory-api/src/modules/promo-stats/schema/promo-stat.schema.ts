import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose';

import { AbstractDocument } from '@base/database/mongodb/abstract.schema';

/** Which promotional surface a stat row belongs to. */
export enum PromoKind {
  BANNER = 'banner',
  POPUP = 'popup',
}

/**
 * One row per (surface, campaign, day) of impression/click counters.
 *
 * Its OWN collection, deliberately NOT counters on the config documents: both
 * configs are saved WHOLESALE from the admin panel (slides replace as a unit),
 * so a counter living there would be silently reset by every edit — and an
 * `$inc` racing that save would resurrect deleted slides. Counters that only
 * ever move by `$inc` upsert cannot lose either race.
 *
 * Keyed by `campaignKey` — the same content hash (`campaignKeyFor`) the popup
 * click system already uses as campaign identity — so editing a creative
 * starts a fresh stat row, and restoring an old creative resumes its history.
 * Split by DAY so the admin can later chart a campaign over time; totals are
 * one small aggregation away.
 */
@Schema({ collection: 'home_promo_stats' })
export class PromoStat extends AbstractDocument {
  @Prop({ type: String, enum: PromoKind, required: true })
  kind: PromoKind;

  @Prop({ type: String, required: true })
  campaignKey: string;

  /** UTC calendar day, `YYYY-MM-DD` — see `utcDayOf`. */
  @Prop({ type: String, required: true })
  date: string;

  @Prop({ type: Number, default: 0 })
  impressions: number;

  @Prop({ type: Number, default: 0 })
  clicks: number;
}

export const PromoStatSchema = SchemaFactory.createForClass(PromoStat);

// One row per surface per campaign per day; every write is an $inc upsert
// against exactly this key.
PromoStatSchema.index({ kind: 1, campaignKey: 1, date: 1 }, { unique: true });
