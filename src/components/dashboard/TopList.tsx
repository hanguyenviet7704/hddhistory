import React from "react";

import { formatNumber } from "./dashboardTheme";

export interface TopListRow {
  id?: string | null;
  name: string;
  users: number;
  events?: number;
}

interface Props {
  rows: TopListRow[];
  /** Column heading for the measure, e.g. "Người đọc". */
  measureLabel?: string;
  emptyText?: string;
  color?: string;
}

/**
 * A ranked list where the bar is background, not decoration: the number is
 * always printed, so the row survives a reader who cannot separate the fill
 * from the surface.
 */
const TopList: React.FC<Props> = ({
  rows,
  measureLabel = "Người dùng",
  emptyText = "Chưa có dữ liệu trong kỳ",
  color = "#2a78d6",
}) => {
  if (!rows.length) {
    return <p className="py-8 text-center text-sm text-gray-500">{emptyText}</p>;
  }

  const max = Math.max(...rows.map((row) => row.users), 1);

  return (
    <ol className="space-y-1.5">
      <li className="flex items-center justify-between px-1 text-[11px] font-medium uppercase tracking-wide text-gray-400">
        <span>Nội dung</span>
        <span>{measureLabel}</span>
      </li>
      {rows.map((row, index) => (
        <li
          key={row.id ?? `${row.name}-${index}`}
          className="relative overflow-hidden rounded-lg border border-gray-100 bg-gray-50"
        >
          <div
            className="absolute inset-y-0 left-0 opacity-15"
            style={{
              width: `${(row.users / max) * 100}%`,
              backgroundColor: color,
            }}
            aria-hidden
          />
          <div className="relative flex items-center justify-between gap-3 px-3 py-2">
            <span className="flex min-w-0 items-center gap-2">
              <span className="w-5 shrink-0 text-xs font-semibold text-gray-400">
                {index + 1}
              </span>
              <span className="truncate text-sm text-gray-800" title={row.name}>
                {row.name}
              </span>
            </span>
            <span className="shrink-0 text-sm font-semibold text-gray-900">
              {formatNumber(row.users)}
              {row.events !== undefined && (
                <span className="ml-1 text-xs font-normal text-gray-500">
                  / {formatNumber(row.events)} lượt
                </span>
              )}
            </span>
          </div>
        </li>
      ))}
    </ol>
  );
};

export default TopList;
