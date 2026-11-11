import { Injectable, Logger } from '@nestjs/common';
import { InjectConnection, InjectModel } from '@nestjs/mongoose';
import { Connection, Model } from 'mongoose';

import { AbstractRepository } from '@base/database/mongodb/abstract.repository';

import { PromoKind, PromoStat } from '../schema/promo-stat.schema';

/** Totals for one campaign, as the admin panel displays them. */
export interface PromoStatTotals {
  impressions: number;
  clicks: number;
  /** clicks / impressions, 0 when nothing was shown yet. */
  ctr: number;
}

/** The UTC calendar day a moment falls on, as the stat rows are keyed. */
export function utcDayOf(now: Date): string {
  return now.toISOString().slice(0, 10);
}

@Injectable()
export class PromoStatRepository extends AbstractRepository<PromoStat> {
  protected readonly logger = new Logger(PromoStatRepository.name);

  constructor(
    @InjectModel(PromoStat.name) model: Model<PromoStat>,
    @InjectConnection() connection: Connection,
  ) {
    super(model, connection);
  }

  /**
   * Count one impression or click, creating today's row on first touch.
   *
   * A pure `$inc` upsert: idempotency is deliberately NOT attempted here (an
   * impression is not unique per user the way a popup click is), and the
   * write can never conflict with the admin saving the config, because these
   * rows are in their own collection.
   */
  async increment(
    kind: PromoKind,
    campaignKey: string,
    field: 'impressions' | 'clicks',
    now = new Date(),
  ): Promise<void> {
    await this.model.updateOne(
      { kind, campaignKey, date: utcDayOf(now) },
      {
        $inc: { [field]: 1 },
        $setOnInsert: { createdAt: now },
        $set: { updatedAt: now },
      },
      { upsert: true },
    );
  }

  /**
   * Lifetime totals per campaign, for the admin panel's stats columns.
   *
   * One aggregation over the (indexed) keys rather than a query per campaign;
   * campaigns with no rows yet simply do not appear — the caller treats
   * absence as zero.
   */
  async totalsFor(
    kind: PromoKind,
    campaignKeys: string[],
  ): Promise<Record<string, PromoStatTotals>> {
    const keys = campaignKeys.filter(key => key.length > 0);
    if (keys.length === 0) return {};

    const rows = await this.model.aggregate<{
      _id: string;
      impressions: number;
      clicks: number;
    }>([
      { $match: { kind, campaignKey: { $in: keys } } },
      {
        $group: {
          _id: '$campaignKey',
          impressions: { $sum: '$impressions' },
          clicks: { $sum: '$clicks' },
        },
      },
    ]);

    const totals: Record<string, PromoStatTotals> = {};
    for (const row of rows) {
      totals[row._id] = {
        impressions: row.impressions,
        clicks: row.clicks,
        ctr: row.impressions > 0 ? row.clicks / row.impressions : 0,
      };
    }

    return totals;
  }
}
