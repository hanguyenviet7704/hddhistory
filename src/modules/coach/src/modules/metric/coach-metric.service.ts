import { Injectable } from '@nestjs/common';

import {
  COACH_METRIC_META,
  COACH_METRIC_REF_LIMIT,
  COACH_METRIC_WEEK_LIMIT,
  CoachMetricGroup,
} from './constant/coach-metric.constant';
import { GetCoachMetricsDto } from './dto/coach-metric.dto';
import { CoachMetricKind } from './enum/coach-metric.enum';
import { CoachMetricRepository } from './repository/coach-metric.repository';

/** ISO week key, `YYYY-Www`. */
export function isoWeekOf(date: Date): string {
  const d = new Date(
    Date.UTC(date.getUTCFullYear(), date.getUTCMonth(), date.getUTCDate()),
  );
  // ISO weeks run Monday-Sunday and belong to the year of their Thursday.
  const day = d.getUTCDay() || 7;
  d.setUTCDate(d.getUTCDate() + 4 - day);
  const yearStart = new Date(Date.UTC(d.getUTCFullYear(), 0, 1));
  const week = Math.ceil(((d.getTime() - yearStart.getTime()) / 86_400_000 + 1) / 7);

  return `${d.getUTCFullYear()}-W${String(week).padStart(2, '0')}`;
}

/**
 * Counts that watch the Coach.
 *
 * Deliberately fire-and-forget: a metric that fails must never fail the turn
 * the reader is in the middle of. Every call swallows its own error.
 */
@Injectable()
export class CoachMetricService {
  constructor(private readonly repository: CoachMetricRepository) {}

  async bump(kind: CoachMetricKind, refId: string | null = null) {
    try {
      await this.repository.bump(kind, isoWeekOf(new Date()), refId);
    } catch {
      // Counting is not worth interrupting a conversation for.
    }
  }

  async findByWeek(isoWeek: string) {
    return this.repository.findByWeek(isoWeek);
  }

  /**
   * One week's counters, labelled and grouped, for the admin panel.
   *
   * Every kind in [CoachMetricKind] is returned even when its count is zero:
   * "the guard never fired this week" and "nobody has wired the guard up" look
   * identical if the row is simply absent, and they are very different news.
   */
  async findForAdmin(dto: GetCoachMetricsDto) {
    const weeks = await this.repository.distinctWeeks(COACH_METRIC_WEEK_LIMIT);
    // Falling back to the newest week WITH DATA rather than to this calendar
    // week: opening the page on an empty current week would read as an outage.
    const isoWeek = dto.isoWeek ?? weeks[0] ?? isoWeekOf(new Date());

    const rows = await this.repository.findByWeek(isoWeek);

    const totals = new Map<string, number>();
    const refs = new Map<string, { refId: string; count: number }[]>();

    for (const row of rows) {
      totals.set(row.kind, (totals.get(row.kind) ?? 0) + row.count);
      if (!row.refId) continue;

      const list = refs.get(row.kind) ?? [];
      list.push({ refId: row.refId, count: row.count });
      refs.set(row.kind, list);
    }

    const items = Object.values(CoachMetricKind).map((kind) => {
      const meta = COACH_METRIC_META[kind];

      return {
        kind,
        label: meta?.label ?? kind,
        group: meta?.group ?? CoachMetricGroup.QUALITY,
        refLabel: meta?.refLabel ?? null,
        count: totals.get(kind) ?? 0,
        refs: (refs.get(kind) ?? [])
          .sort((a, b) => b.count - a.count)
          .slice(0, COACH_METRIC_REF_LIMIT),
      };
    });

    return {
      isoWeek,
      weeks,
      hasData: rows.length > 0,
      items,
    };
  }
}
