import React from "react";
import {
  CartesianGrid,
  Legend,
  Line,
  LineChart,
  ResponsiveContainer,
  Tooltip,
  XAxis,
  YAxis,
} from "recharts";

import { IRetentionPoint } from "../../types/interface/dashboard.interface";
import ChartTooltip from "./ChartTooltip";
import {
  AXIS_PROPS,
  GRID_PROPS,
  SERIES,
  formatPercent,
} from "./dashboardTheme";

export interface RetentionSeries {
  key: string;
  label: string;
  points: IRetentionPoint[];
}

interface Props {
  series: RetentionSeries[];
}

// Fixed order, never cycled: a fourth series would need a generated hue, and a
// generated hue is what breaks colour-blind separation. Callers cap at three
// and fold the rest away instead.
const SERIES_COLORS = [SERIES.active, SERIES.new, SERIES.engaged];

/**
 * "Of the people who signed up, what share came back on day N."
 *
 * One row per offset, one line per series. A cohort too young to have reached
 * an offset contributes `null`, which Recharts draws as a gap — the line simply
 * stops rather than diving to zero, because "not measured yet" is not "nobody
 * came back".
 */
const RetentionCurve: React.FC<Props> = ({ series }) => {
  const offsets = Array.from(
    new Set(
      series.flatMap((entry) => entry.points.map((point) => point.offset))
    )
  ).sort((a, b) => a - b);

  const rows = offsets.map((offset) => {
    const row: Record<string, number | string | null> = {
      offset: `Ngày ${offset}`,
    };
    for (const entry of series) {
      const point = entry.points.find((item) => item.offset === offset);
      row[entry.key] = point?.rate ?? null;
    }
    return row;
  });

  return (
    <ResponsiveContainer width="100%" height="100%">
      <LineChart data={rows} margin={{ top: 8, right: 16, bottom: 0, left: -8 }}>
        <CartesianGrid {...GRID_PROPS} />
        <XAxis dataKey="offset" {...AXIS_PROPS} />
        <YAxis
          domain={[0, 1]}
          tickFormatter={(value) => formatPercent(Number(value))}
          {...AXIS_PROPS}
        />
        <Tooltip
          content={
            <ChartTooltip valueFormatter={(value) => formatPercent(value)} />
          }
        />
        {series.length > 1 && (
          <Legend
            iconType="plainline"
            wrapperStyle={{ fontSize: 12, paddingTop: 8 }}
          />
        )}
        {series.map((entry, index) => (
          <Line
            key={entry.key}
            type="monotone"
            dataKey={entry.key}
            name={entry.label}
            stroke={SERIES_COLORS[index % SERIES_COLORS.length]}
            strokeWidth={2}
            dot={{ r: 3 }}
            activeDot={{ r: 5 }}
            connectNulls={false}
          />
        ))}
      </LineChart>
    </ResponsiveContainer>
  );
};

export default RetentionCurve;
