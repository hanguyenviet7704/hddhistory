import { ArrowDownIcon, ArrowUpIcon } from "@heroicons/react/24/outline";

import { formatNumber } from "./lesson-feedback-utils";

interface Props {
  label: string;
  value: number | null;
  hint?: string;
  suffix?: string;
  denominator?: string;
  /**
   * Null means "no comparable previous period" (an all-time query), which is
   * why the row is dropped instead of drawing a green +0% — a fake baseline
   * reads as real movement.
   */
  delta?: number | null;
}

const LessonFeedbackMetricCard = ({
  label,
  value,
  hint,
  suffix = "",
  denominator,
  delta,
}: Props) => {
  const positive = (delta ?? 0) >= 0;

  return (
    <div className="rounded-2xl border border-slate-200 bg-white p-5 shadow-sm">
      <div className="text-sm font-medium text-slate-500">{label}</div>
      <div className="mt-4 flex items-end gap-1">
        <span className="text-4xl font-bold tracking-normal text-slate-950">
          {formatNumber(value)}
          {value === null ? "" : suffix}
        </span>
        {denominator ? (
          <span className="mb-1 text-xl font-semibold text-slate-400">
            / {denominator}
          </span>
        ) : null}
      </div>
      {delta === null || delta === undefined ? (
        hint ? <div className="mt-3 text-xs text-slate-400">{hint}</div> : null
      ) : (
        <div
          className={`mt-3 inline-flex items-center gap-1 text-sm font-semibold ${
            positive ? "text-emerald-600" : "text-red-600"
          }`}
        >
          {positive ? (
            <ArrowUpIcon className="h-4 w-4" />
          ) : (
            <ArrowDownIcon className="h-4 w-4" />
          )}
          {Math.abs(delta)}% <span className="font-normal text-slate-400">vs kỳ trước</span>
        </div>
      )}
    </div>
  );
};

export default LessonFeedbackMetricCard;
