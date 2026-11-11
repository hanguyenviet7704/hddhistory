import { Injectable, Logger } from '@nestjs/common';
import { InjectConnection, InjectModel } from '@nestjs/mongoose';
import { Connection, Model } from 'mongoose';

import { AbstractRepository } from '@base/database/mongodb/abstract.repository';

import { AnalyticsDaily } from '../schema/analytics-daily.schema';

@Injectable()
export class AnalyticsDailyRepository extends AbstractRepository<AnalyticsDaily> {
  protected readonly logger = new Logger(AnalyticsDailyRepository.name);

  constructor(
    @InjectModel(AnalyticsDaily.name) model: Model<AnalyticsDaily>,
    @InjectConnection() connection: Connection,
  ) {
    super(model, connection);
  }

  /**
   * Write one day, replacing whatever was there.
   *
   * Upsert rather than insert so re-running the cron (after a deploy, or by
   * hand to backfill) corrects the day instead of duplicating it.
   */
  async upsertDay(
    date: string,
    appEnv: string,
    data: Partial<AnalyticsDaily>,
  ): Promise<void> {
    await this.model.updateOne(
      { date, appEnv },
      { $set: { ...data, date, appEnv, updatedAt: new Date() } },
      { upsert: true },
    );
  }

  async findRange(
    from: string,
    to: string,
    appEnv: string,
  ): Promise<AnalyticsDaily[]> {
    return this.model
      .find({ appEnv, date: { $gte: from, $lte: to } })
      .sort({ date: 1 })
      .lean<AnalyticsDaily[]>();
  }

  /** Latest day already written, so a backfill knows where to resume. */
  async findLatestDate(appEnv: string): Promise<string | null> {
    const [row] = await this.model
      .find({ appEnv }, { date: 1 })
      .sort({ date: -1 })
      .limit(1)
      .lean<{ date: string }[]>();

    return row?.date ?? null;
  }
}
