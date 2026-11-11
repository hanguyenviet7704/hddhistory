import React from "react";

import {
  SERIES,
  formatDuration,
  formatNumber,
  formatPercent,
} from "../../../components/dashboard/dashboardTheme";
import {
  ICoachBreakdownRow,
  ICoachFunnelStep,
  ICoachNumericStats,
  ICoachOutcomeRow,
} from "../../../types/interface/coachStats.interface";

/**
 * A numbered block of the Coach page.
 *
 * The numbers are load-bearing rather than decorative: the four blocks are one
 * journey in order — the door, the conversation, how it ended, what was shown
 * along the way — and a reader who lands mid-page needs to know where they are.
 */
export const SectionCard: React.FC<{
  index: string;
  title: string;
  description?: string;
  action?: React.ReactNode;
  children: React.ReactNode;
}> = ({ index, title, description, action, children }) => (
  <section className="rounded-xl border border-gray-200 bg-white p-4 shadow-sm">
    <div className="flex flex-wrap items-start justify-between gap-2">
      <div className="flex items-start gap-2.5">
        <span
          className="mt-0.5 flex h-6 w-6 shrink-0 items-center justify-center rounded-full text-xs font-semibold text-white"
          style={{ backgroundColor: SERIES.active }}
          aria-hidden
        >
          {index}
        </span>
        <div>
          <h2 className="text-sm font-semibold text-gray-900">{title}</h2>
          {description && (
            <p className="mt-0.5 max-w-3xl text-xs text-gray-500">
              {description}
            </p>
          )}
        </div>
      </div>
      {action}
    </div>
    <div className="mt-4">{children}</div>
  </section>
);

/**
 * One step of a door funnel.
 *
 * Bar width carries the shape, the counts carry the fact. `passRate` is a share
 * of PEOPLE — a bubble is seen many times a day by the same reader, so a rate
 * over raw events would measure how often the shell rebuilt.
 */
export const FunnelRow: React.FC<{
  step: ICoachFunnelStep;
  first: number;
}> = ({ step, first }) => {
  const width = first ? Math.max((step.users / first) * 100, 2) : 0;

  return (
    <li className="space-y-1">
      <div className="flex items-baseline justify-between gap-3 text-sm">
        <span className="truncate font-medium text-gray-800">{step.label}</span>
        <span className="shrink-0 tabular-nums text-gray-900">
          {formatNumber(step.users)} người
          <span className="ml-1.5 text-xs font-normal text-gray-500">
            {formatPercent(step.passRate)} · {formatNumber(step.events)} lượt
          </span>
        </span>
      </div>
      <div className="flex items-center gap-2">
        <div className="h-2.5 flex-1 overflow-hidden rounded-full bg-gray-100">
          <div
            className="h-full rounded-full"
            style={{ width: `${width}%`, backgroundColor: SERIES.active }}
          />
        </div>
        {step.dropUsers > 0 && (
          <span
            className="shrink-0 rounded-full bg-rose-50 px-2 py-0.5 text-[11px] font-medium text-rose-700"
            title="So với bước liền trước"
          >
            −{formatNumber(step.dropUsers)} ({formatPercent(step.dropRate)})
          </span>
        )}
      </div>
    </li>
  );
};

/**
 * A `params` breakdown, ranked.
 *
 * Deliberately not the shared `TopList`: that one leads with distinct users,
 * and every breakdown here is about lượt — which door was used, which kind of
 * turn was sent, which beat somebody left on. People are the second number, in
 * smaller type, so both questions are answerable off one row.
 */
export const BreakdownList: React.FC<{
  rows: ICoachBreakdownRow[];
  emptyText?: string;
  color?: string;
}> = ({
  rows,
  emptyText = "Chưa có dữ liệu trong kỳ",
  color = SERIES.active,
}) => {
  if (!rows.length) {
    return (
      <p className="py-6 text-center text-sm text-gray-500">{emptyText}</p>
    );
  }

  const max = Math.max(...rows.map((row) => row.events), 1);

  return (
    <ol className="space-y-1.5">
      {rows.map((row, index) => (
        <li
          key={row.id || `row-${index}`}
          className="relative overflow-hidden rounded-lg border border-gray-100 bg-gray-50"
        >
          <div
            className="absolute inset-y-0 left-0 opacity-15"
            style={{
              width: `${(row.events / max) * 100}%`,
              backgroundColor: color,
            }}
            aria-hidden
          />
          <div className="relative flex items-center justify-between gap-3 px-3 py-2">
            <span className="truncate text-sm text-gray-800" title={row.label}>
              {row.label}
            </span>
            <span className="shrink-0 text-right text-sm font-semibold tabular-nums text-gray-900">
              {formatNumber(row.events)}
              <span className="ml-1.5 text-xs font-normal text-gray-500">
                {formatPercent(row.share)} · {formatNumber(row.users)} người
              </span>
            </span>
          </div>
        </li>
      ))}
    </ol>
  );
};

/** Đi hết đường hay bỏ dở, tách theo cửa vào. */
export const OutcomeTable: React.FC<{ rows: ICoachOutcomeRow[] }> = ({
  rows,
}) => {
  if (!rows.length) {
    return (
      <p className="py-6 text-center text-sm text-gray-500">
        Chưa có phiên nào kết thúc trong kỳ
      </p>
    );
  }

  return (
    <div className="overflow-x-auto">
      <table className="w-full min-w-[420px] text-sm">
        <thead>
          <tr className="text-[11px] uppercase tracking-wide text-gray-400">
            <th className="pb-2 text-left font-medium">Cửa vào</th>
            <th className="pb-2 text-right font-medium">Đi hết</th>
            <th className="pb-2 text-right font-medium">Bỏ dở</th>
            <th className="pb-2 text-right font-medium">Tỉ lệ hoàn thành</th>
          </tr>
        </thead>
        <tbody className="divide-y divide-gray-100">
          {rows.map((row) => (
            <tr key={row.id || row.label}>
              <td className="py-2 pr-3 text-gray-800">{row.label}</td>
              <td className="py-2 text-right tabular-nums text-gray-900">
                {formatNumber(row.completed)}
              </td>
              <td className="py-2 text-right tabular-nums text-gray-900">
                {formatNumber(row.abandoned)}
              </td>
              <td className="py-2 text-right font-semibold tabular-nums text-gray-900">
                {formatPercent(row.completionRate)}
              </td>
            </tr>
          ))}
        </tbody>
      </table>
    </div>
  );
};

/**
 * A numeric param, finished sessions beside abandoned ones.
 *
 * The pair is the point. "Median 3 phút" alone says nothing; three minutes for
 * a session that finished and twenty seconds for one that did not is the
 * difference between a Coach people leave because it is done and a Coach people
 * leave because it lost them.
 */
export const StatsPair: React.FC<{
  title: string;
  completed: ICoachNumericStats;
  abandoned: ICoachNumericStats;
  /** Seconds render as "3p 12s"; plain counts render as numbers. */
  asDuration?: boolean;
}> = ({ title, completed, abandoned, asDuration }) => {
  const show = (value: number | null) =>
    asDuration
      ? formatDuration(value === null ? null : value * 1000)
      : value === null
        ? "—"
        : value.toFixed(value % 1 === 0 ? 0 : 1);

  const rows: { label: string; stats: ICoachNumericStats }[] = [
    { label: "Đi hết đường", stats: completed },
    { label: "Bỏ giữa chừng", stats: abandoned },
  ];

  return (
    <div className="rounded-lg border border-gray-100 bg-gray-50 p-3">
      <p className="text-xs font-semibold uppercase tracking-wide text-gray-500">
        {title}
      </p>
      <table className="mt-2 w-full text-sm">
        <thead>
          <tr className="text-[11px] uppercase tracking-wide text-gray-400">
            <th className="pb-1 text-left font-medium" />
            <th className="pb-1 text-right font-medium">Trung vị</th>
            <th className="pb-1 text-right font-medium">P90</th>
            <th className="pb-1 text-right font-medium">Phiên</th>
          </tr>
        </thead>
        <tbody className="divide-y divide-gray-200">
          {rows.map((row) => (
            <tr key={row.label}>
              <td className="py-1.5 pr-2 text-gray-700">{row.label}</td>
              <td className="py-1.5 text-right font-semibold tabular-nums text-gray-900">
                {show(row.stats.median)}
              </td>
              <td className="py-1.5 text-right tabular-nums text-gray-700">
                {show(row.stats.p90)}
              </td>
              <td className="py-1.5 text-right tabular-nums text-gray-500">
                {formatNumber(row.stats.count)}
              </td>
            </tr>
          ))}
        </tbody>
      </table>
    </div>
  );
};
