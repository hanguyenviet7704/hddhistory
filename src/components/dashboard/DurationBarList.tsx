import React from "react";

import { SERIES, formatDuration, formatNumber } from "./dashboardTheme";

export interface DurationRow {
  label: string;
  ms: number | null;
  sessions: number;
}

interface Props {
  rows: DurationRow[];
  color?: string;
  emptyText?: string;
}

/**
 * Horizontal bars for "how long is a session, sliced by X".
 *
 * Plain HTML rather than a chart component: the rows are few, the labels are
 * words, and the value has to be readable as a duration ("3p 44s") rather than
 * a number on an axis. The bar is proportion; the printed value is the truth.
 */
const DurationBarList: React.FC<Props> = ({
  rows,
  color = SERIES.active,
  emptyText = "Chưa có dữ liệu trong kỳ",
}) => {
  if (!rows.length) {
    return <p className="py-8 text-center text-sm text-gray-500">{emptyText}</p>;
  }

  const max = Math.max(...rows.map((row) => row.ms ?? 0), 1);

  return (
    <ul className="space-y-2">
      {rows.map((row) => (
        <li key={row.label} className="flex items-center gap-3">
          <span className="w-20 shrink-0 text-sm text-gray-600">
            {row.label}
          </span>
          <div className="h-2.5 flex-1 overflow-hidden rounded-full bg-gray-100">
            <div
              className="h-full rounded-full"
              style={{
                width: `${((row.ms ?? 0) / max) * 100}%`,
                backgroundColor: color,
              }}
              // The session count is what tells you whether a long median is a
              // real pattern or three people on a quiet Sunday.
              title={`${formatNumber(row.sessions)} phiên`}
            />
          </div>
          <span className="w-16 shrink-0 text-right text-sm font-medium tabular-nums text-gray-900">
            {formatDuration(row.ms)}
          </span>
        </li>
      ))}
    </ul>
  );
};

export default DurationBarList;
