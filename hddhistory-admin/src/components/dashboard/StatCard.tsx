import React from "react";
import {
  ArrowDownRightIcon,
  ArrowRightIcon,
  ArrowUpRightIcon,
} from "@heroicons/react/24/outline";

import { formatNumber } from "./dashboardTheme";

interface DeltaProps {
  current: number;
  previous: number | null | undefined;
  /** Set when a fall is the good outcome (e.g. drop-off). */
  invert?: boolean;
}

/**
 * Change vs the previous period.
 *
 * Renders nothing when there is no comparison figure — an empty slot is honest,
 * a "+100%" against a period we never measured is not. Direction is carried by
 * an arrow as well as colour, so it survives a colour-blind reader.
 */
export const DeltaBadge: React.FC<DeltaProps> = ({
  current,
  previous,
  invert,
}) => {
  if (previous === null || previous === undefined) return null;

  if (previous === 0) {
    // A percentage against zero is meaningless; show the absolute move instead.
    if (current === 0) return null;
    return (
      <span className="inline-flex items-center gap-1 rounded-full bg-gray-100 px-2 py-0.5 text-xs font-medium text-gray-600">
        <ArrowUpRightIcon className="h-3 w-3" />+{formatNumber(current)}
      </span>
    );
  }

  const change = (current - previous) / Math.abs(previous);
  const flat = Math.abs(change) < 0.005;
  const good = invert ? change < 0 : change > 0;

  const tone = flat
    ? "bg-gray-100 text-gray-600"
    : good
    ? "bg-emerald-50 text-emerald-700"
    : "bg-rose-50 text-rose-700";

  const Icon = flat
    ? ArrowRightIcon
    : change > 0
    ? ArrowUpRightIcon
    : ArrowDownRightIcon;

  return (
    <span
      className={`inline-flex items-center gap-1 rounded-full px-2 py-0.5 text-xs font-medium ${tone}`}
      title={`Kỳ trước: ${formatNumber(previous)}`}
    >
      <Icon className="h-3 w-3" />
      {flat ? "không đổi" : `${Math.abs(change * 100).toFixed(1)}%`}
    </span>
  );
};

interface Props {
  label: string;
  value: string;
  hint?: string;
  /** Rendered under the value — usually a <DeltaBadge/>. */
  delta?: React.ReactNode;
  icon?: React.ReactNode;
  accent?: string;
}

const StatCard: React.FC<Props> = ({
  label,
  value,
  hint,
  delta,
  icon,
  accent,
}) => (
  <div className="rounded-xl border border-gray-200 bg-white p-4 shadow-sm">
    <div className="flex items-start justify-between gap-2">
      <span className="text-sm font-medium text-gray-500">{label}</span>
      {icon && <span className="text-gray-400">{icon}</span>}
    </div>
    <div className="mt-2 flex items-baseline gap-2">
      <span
        className="text-2xl font-semibold text-gray-900"
        style={accent ? { color: accent } : undefined}
      >
        {value}
      </span>
      {delta}
    </div>
    {hint && <p className="mt-1 text-xs text-gray-500">{hint}</p>}
  </div>
);

export default StatCard;
