import React from "react";

import { formatNumber } from "./dashboardTheme";

interface Props {
  active?: boolean;
  payload?: any[];
  label?: string | number;
  /** Turns the axis value into the tooltip's heading. */
  labelFormatter?: (label: any) => string;
  /** Per-series value formatting; defaults to a thousands-separated number. */
  valueFormatter?: (value: number, key: string) => string;
}

/**
 * One tooltip for every chart on the dashboard.
 *
 * A colour chip carries the series identity and the series name is spelled out
 * beside it — the tooltip is the place a colour-blind reader resolves which
 * line is which, so it never relies on the swatch alone.
 */
const ChartTooltip: React.FC<Props> = ({
  active,
  payload,
  label,
  labelFormatter,
  valueFormatter,
}) => {
  if (!active || !payload?.length) return null;

  return (
    <div className="rounded-lg border border-gray-200 bg-white px-3 py-2 shadow-lg">
      {label !== undefined && (
        <p className="mb-1 text-xs font-medium text-gray-500">
          {labelFormatter ? labelFormatter(label) : label}
        </p>
      )}
      <ul className="space-y-0.5">
        {payload.map((entry) => (
          <li
            key={entry.dataKey ?? entry.name}
            className="flex items-center gap-2 text-sm"
          >
            <span
              className="h-2.5 w-2.5 shrink-0 rounded-sm"
              style={{ backgroundColor: entry.color ?? entry.fill }}
              aria-hidden
            />
            <span className="text-gray-600">{entry.name}</span>
            <span className="ml-auto font-semibold text-gray-900">
              {valueFormatter
                ? valueFormatter(entry.value, String(entry.dataKey))
                : formatNumber(entry.value)}
            </span>
          </li>
        ))}
      </ul>
    </div>
  );
};

export default ChartTooltip;
