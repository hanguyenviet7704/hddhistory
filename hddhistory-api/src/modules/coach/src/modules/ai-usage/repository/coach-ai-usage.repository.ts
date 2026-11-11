import { Injectable, Logger } from '@nestjs/common';
import { InjectConnection, InjectModel } from '@nestjs/mongoose';
import { Connection, Model } from 'mongoose';

import { AbstractRepository } from '@base/database/mongodb/abstract.repository';

import { CoachSession } from '../../session/schema/coach-session.schema';
import { CoachAiUsage } from '../schema/coach-ai-usage.schema';

export interface ICoachAiUsageGroup {
  key: string;
  calls: number;
  failedCalls: number;
  inputTokens: number;
  outputTokens: number;
  costVnd: number;
  /**
   * Latency PER GROUP, not just overall.
   *
   * The window average alone cannot answer the only question worth asking of
   * this report — "which step is the reader waiting on" — because the cheapest
   * call is also the most frequent: 3,758 of 8,955 calls in a week were the two
   * lite-model gates, and they drag the mean far below what any conversational
   * turn actually costs. The per-kind mean had to be reconstructed by hand
   * (subtract the gates, divide the rest) to find that a conversational call
   * averages ~4.7s. That arithmetic belongs here, once.
   */
  avgLatencyMs: number;
  /** The worst one in the window — where the timeout ceiling gets tested. */
  maxLatencyMs: number;
}

/** How a window's failures break down, worst first. */
export interface ICoachAiUsageError {
  /** `errorCode` — '429', '503', 'timeout', 'blocked', 'malformed', … */
  key: string;
  calls: number;
  /** Which steps it hit, so a provider refusal can be traced to a beat. */
  kinds: string[];
}

@Injectable()
export class CoachAiUsageRepository extends AbstractRepository<CoachAiUsage> {
  protected readonly logger = new Logger(CoachAiUsageRepository.name);

  constructor(
    @InjectModel(CoachAiUsage.name) model: Model<CoachAiUsage>,
    /**
     * Read-only, and only to divide by.
     *
     * Cost per session is the number that says whether this feature is
     * affordable, and it needs a denominator this collection does not have. The
     * session MODEL is injected rather than the session module imported, because
     * `CoachSessionModule` already depends on the AI module that depends on this
     * one — importing it back would close the cycle.
     */
    @InjectModel(CoachSession.name)
    private readonly sessionModel: Model<CoachSession>,
    @InjectConnection() connection: Connection,
  ) {
    super(model, connection);
  }

  /**
   * Writes one row, and never throws.
   *
   * The caller is a coach turn already waiting on a model — a telemetry insert
   * failing must not turn a working reply into an error, and must not be retried
   * either. `insertMany` with `ordered: false` is not needed for one document;
   * plain create with a swallowed error is the whole contract.
   */
  async record(row: Partial<CoachAiUsage>): Promise<void> {
    try {
      await this.model.create(row);
    } catch (error: any) {
      this.logger.warn(`Could not record coach AI usage: ${error?.message}`);
    }
  }

  /** Totals over a server-date window, grouped by one field. */
  async groupBy(
    field: 'kind' | 'model' | 'serverDate',
    range: { from: string; to: string },
  ): Promise<ICoachAiUsageGroup[]> {
    const rows = await this.model.aggregate<ICoachAiUsageGroup>([
      { $match: { serverDate: { $gte: range.from, $lte: range.to } } },
      {
        $group: {
          _id: `$${field}`,
          calls: { $sum: 1 },
          // `ok` is a boolean, so the failed count has to be a conditional sum
          // rather than a second query — one pass over the window, not two.
          failedCalls: { $sum: { $cond: ['$ok', 0, 1] } },
          inputTokens: { $sum: '$inputTokens' },
          outputTokens: { $sum: '$outputTokens' },
          costVnd: { $sum: '$costVnd' },
          avgLatencyMs: { $avg: '$latencyMs' },
          maxLatencyMs: { $max: '$latencyMs' },
        },
      },
      {
        $project: {
          _id: 0,
          key: '$_id',
          calls: 1,
          failedCalls: 1,
          inputTokens: 1,
          outputTokens: 1,
          costVnd: 1,
          // Rounded in the aggregation rather than at the report: unlike
          // `costVnd`, a fractional millisecond carries no information that a
          // later sum could recover.
          avgLatencyMs: { $round: ['$avgLatencyMs', 0] },
          maxLatencyMs: 1,
        },
      },
      { $sort: { costVnd: -1 } },
    ]);

    return rows;
  }

  /**
   * What went wrong in the window, grouped by code.
   *
   * Its own aggregation rather than another field on `groupBy`: failures are
   * sparse, and the reader of this section wants them cut by CODE (is the
   * provider refusing us, or are we timing out?) rather than by whichever
   * dimension the row above happens to use.
   */
  async errorBreakdown(range: {
    from: string;
    to: string;
  }): Promise<ICoachAiUsageError[]> {
    return this.model.aggregate<ICoachAiUsageError>([
      {
        $match: {
          serverDate: { $gte: range.from, $lte: range.to },
          errorCode: { $ne: null },
        },
      },
      {
        $group: {
          _id: '$errorCode',
          calls: { $sum: 1 },
          kinds: { $addToSet: '$kind' },
        },
      },
      { $project: { _id: 0, key: '$_id', calls: 1, kinds: 1 } },
      { $sort: { calls: -1 } },
    ]);
  }

  /**
   * The denominator: how many sessions ran in the window, and how many people.
   *
   * Server time, matching `serverDate` on the usage rows — mixing a reader's own
   * calendar day with a server one would make the ratio drift by a day's spend
   * at every timezone boundary.
   */
  async sessionStats(range: {
    from: Date;
    to: Date;
  }): Promise<{ count: number; users: number }> {
    const where = { createdAt: { $gte: range.from, $lte: range.to } };
    const [count, users] = await Promise.all([
      this.sessionModel.countDocuments(where),
      this.sessionModel.distinct('userId', where),
    ]);

    return { count, users: users.length };
  }

  /** Slowest-first latency percentiles are overkill; the mean is the signal. */
  async averageLatencyMs(range: { from: string; to: string }): Promise<number> {
    const [row] = await this.model.aggregate<{ value: number }>([
      { $match: { serverDate: { $gte: range.from, $lte: range.to } } },
      { $group: { _id: null, value: { $avg: '$latencyMs' } } },
      { $project: { _id: 0, value: 1 } },
    ]);

    return Math.round(row?.value ?? 0);
  }
}
