import { Injectable } from '@nestjs/common';

import { CoachAiCallKind } from './coach-ai-usage.enum';
import {
  estimateCostVnd,
  isPricedModel,
  priceFor,
  USD_TO_VND,
} from './coach-ai-usage.pricing';
import { GetCoachAiUsageDto } from './dto/coach-ai-usage.dto';
import {
  CoachAiUsageRepository,
  ICoachAiUsageGroup,
} from './repository/coach-ai-usage.repository';

/** How far back the report looks when nobody says. */
const DEFAULT_WINDOW_DAYS = 30;

function serverDateOf(date: Date): string {
  const year = date.getFullYear();
  const month = String(date.getMonth() + 1).padStart(2, '0');
  const day = String(date.getDate()).padStart(2, '0');
  return `${year}-${month}-${day}`;
}

@Injectable()
export class CoachAiUsageService {
  constructor(private readonly repository: CoachAiUsageRepository) {}

  /**
   * Books one call. Never awaited by the caller and never throws.
   *
   * The price is applied HERE, at write time, not at read time — see the note on
   * `costVnd` in the schema for why a report that re-prices history is a report
   * nobody can reconcile against an invoice.
   */
  record(call: {
    kind: CoachAiCallKind;
    model: string;
    inputTokens: number;
    outputTokens: number;
    ok: boolean;
    latencyMs: number;
    /** Null on success; see the note on the schema's own `errorCode`. */
    errorCode?: string | null;
  }): void {
    const costVnd = estimateCostVnd(call);

    void this.repository.record({
      ...call,
      errorCode: call.errorCode ?? null,
      costVnd,
      serverDate: serverDateOf(new Date()),
    });
  }

  async summaryForAdmin(dto: GetCoachAiUsageDto) {
    const today = new Date();
    const to = dto.to ?? serverDateOf(today);

    const defaultFrom = new Date(today);
    defaultFrom.setDate(defaultFrom.getDate() - (DEFAULT_WINDOW_DAYS - 1));
    const from = dto.from ?? serverDateOf(defaultFrom);

    const [byKind, byModel, daily, avgLatencyMs, errors, sessions] =
      await Promise.all([
        this.repository.groupBy('kind', { from, to }),
        this.repository.groupBy('model', { from, to }),
        this.repository.groupBy('serverDate', { from, to }),
        this.repository.averageLatencyMs({ from, to }),
        this.repository.errorBreakdown({ from, to }),
        this.repository.sessionStats({
          // End of day, not midnight: `to` names a whole day, and `$lte` on
          // midnight would drop everything that happened during it.
          from: new Date(`${from}T00:00:00`),
          to: new Date(`${to}T23:59:59.999`),
        }),
      ]);

    // Rounded HERE and nowhere earlier: rows store fractional đồng so the many
    // sub-đồng gate calls are not lost to rounding, and the report is the one
    // place a whole number is what a reader wants.
    const round = (group: ICoachAiUsageGroup): ICoachAiUsageGroup => ({
      ...group,
      costVnd: Math.round(group.costVnd),
    });

    const totals = byKind.reduce(
      (accumulator, row) => ({
        calls: accumulator.calls + row.calls,
        failedCalls: accumulator.failedCalls + row.failedCalls,
        inputTokens: accumulator.inputTokens + row.inputTokens,
        outputTokens: accumulator.outputTokens + row.outputTokens,
        costVnd: accumulator.costVnd + row.costVnd,
      }),
      { calls: 0, failedCalls: 0, inputTokens: 0, outputTokens: 0, costVnd: 0 },
    );
    // Summed before rounding, so the total is not the sum of rounded parts.
    const totalCostVnd = Math.round(totals.costVnd);

    return {
      range: { from, to },
      totals: { ...totals, costVnd: totalCostVnd, avgLatencyMs },
      /** Which STEP of the flow the money went to. Sorted dearest first. */
      byKind: byKind.map(round),
      byModel: byModel.map(round),
      /**
       * Every call that did not answer, grouped by why.
       *
       * Sits beside the money rather than inside it because most of these cost
       * NOTHING — a 503 is refused before a token is spent — and a reader
       * scanning `costVnd` would never find them. They are the expensive ones
       * in the only currency that matters here: each is a reader who watched
       * the three dots and got silence.
       */
      errors,
      /** Ascending, so the client can plot it without re-sorting. */
      daily: [...daily]
        .sort((left, right) => left.key.localeCompare(right.key))
        .map(round),
      sessions: {
        ...sessions,
        // Guarded: a window with spend but no sessions is possible (scene
        // generation is admin-triggered), and dividing by it would report
        // Infinity as a price.
        // Divided from the UNROUNDED total: a per-session price computed off a
        // rounded total is off by more than the price itself when the total is
        // small, which is exactly when somebody is checking it.
        costPerSessionVnd: sessions.count
          ? Math.round(totals.costVnd / sessions.count)
          : null,
        costPerUserVnd: sessions.users
          ? Math.round(totals.costVnd / sessions.users)
          : null,
      },
      /**
       * The rates that produced the numbers above, so the report explains itself
       * without anybody opening the source.
       */
      pricing: {
        usdToVnd: USD_TO_VND,
        models: byModel.map(row => ({
          model: row.key,
          usdPerMillionInput: priceFor(row.key).input,
          usdPerMillionOutput: priceFor(row.key).output,
          // False means this model has no entry in the price list and is being
          // charged at the conversational model's rate — usually a sign Google
          // shifted the alias and the constants need a look.
          priced: isPricedModel(row.key),
        })),
      },
    };
  }
}
