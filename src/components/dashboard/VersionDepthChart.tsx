import React from "react";
import {
  Bar,
  BarChart,
  Cell,
  LabelList,
  ResponsiveContainer,
  XAxis,
} from "recharts";

import { SERIES, formatPercent } from "./dashboardTheme";

// One colour per version, fixed by position so a version keeps its colour
// across all four metrics. Never cycled: a fourth version folds away rather
// than borrowing a hue that no longer separates.
const VERSION_COLORS = [SERIES.new, SERIES.active, SERIES.engaged];

export interface VersionMetricPoint {
  appVersion: string;
  value: number | null;
}

interface Props {
  title: string;
  points: VersionMetricPoint[];
  /** Turns the raw value into the label printed above each bar. */
  format: (value: number | null) => string;
  /** Change from the oldest version to the newest. */
  delta: number | null;
  /** "pct" prints ±x%, "points" prints ±x điểm — a rate's change is points. */
  deltaKind?: "pct" | "points";
  /** True when a fall is the good outcome. */
  invert?: boolean;
}

/**
 * One session-depth measure compared across app versions.
 *
 * Bars are labelled with their value: the whole point is comparing three
 * numbers, and making someone estimate them off an axis would be a worse
 * version of a three-row table.
 */
const VersionDepthChart: React.FC<Props> = ({
  title,
  points,
  format,
  delta,
  deltaKind = "pct",
  invert,
}) => {
  const rows = points.map((point) => ({
    appVersion: point.appVersion,
    value: point.value ?? 0,
    label: format(point.value),
  }));

  const good = delta === null ? null : invert ? delta < 0 : delta > 0;
  const deltaText =
    delta === null
      ? null
      : deltaKind === "points"
      ? `${delta > 0 ? "↑" : "↓"} ${Math.abs(delta * 100).toFixed(0)} điểm`
      : `${delta > 0 ? "↑" : "↓"} ${formatPercent(Math.abs(delta))}`;

  return (
    <div className="flex flex-col">
      <p className="mb-2 text-center text-xs font-medium text-gray-600">
        {title}
      </p>
      <div style={{ height: 150 }}>
        <ResponsiveContainer width="100%" height="100%">
          <BarChart data={rows} margin={{ top: 22, right: 4, bottom: 0, left: 4 }}>
            <XAxis
              dataKey="appVersion"
              tick={{ fill: "#94a3b8", fontSize: 10 }}
              tickLine={false}
              axisLine={{ stroke: "#e2e8f0" }}
            />
            <Bar dataKey="value" radius={[4, 4, 0, 0]} isAnimationActive={false}>
              {rows.map((row, index) => (
                <Cell
                  key={row.appVersion}
                  fill={VERSION_COLORS[index % VERSION_COLORS.length]}
                />
              ))}
              <LabelList
                dataKey="label"
                position="top"
                style={{ fill: "#0f172a", fontSize: 12, fontWeight: 600 }}
              />
            </Bar>
          </BarChart>
        </ResponsiveContainer>
      </div>
      {deltaText && (
        <p
          className={`mt-1 text-center text-xs font-medium ${
            good ? "text-emerald-700" : "text-rose-700"
          }`}
        >
          {deltaText}
        </p>
      )}
    </div>
  );
};

export default VersionDepthChart;
