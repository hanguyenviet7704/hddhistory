import React from "react";

interface Props {
  title: string;
  description?: string;
  /** Legend chips, a toggle — anything that belongs on the title row. */
  action?: React.ReactNode;
  height?: number;
  children: React.ReactNode;
}

/**
 * Frame for one chart: a title that says what the chart answers, an optional
 * one-line reading of it, and a fixed-height plot area.
 *
 * The height is fixed rather than aspect-based because Recharts'
 * ResponsiveContainer needs a resolved height from its parent, and a percentage
 * height inside an auto-height flex column collapses to zero.
 */
const ChartCard: React.FC<Props> = ({
  title,
  description,
  action,
  height = 280,
  children,
}) => (
  <section className="rounded-xl border border-gray-200 bg-white p-4 shadow-sm">
    <div className="flex flex-wrap items-start justify-between gap-2">
      <div>
        <h2 className="text-sm font-semibold text-gray-900">{title}</h2>
        {description && (
          <p className="mt-0.5 text-xs text-gray-500">{description}</p>
        )}
      </div>
      {action}
    </div>
    <div className="mt-4" style={{ height }}>
      {children}
    </div>
  </section>
);

export default ChartCard;
