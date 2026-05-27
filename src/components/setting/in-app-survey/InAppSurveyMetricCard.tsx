import { ArrowDownIcon, ArrowUpIcon } from "@heroicons/react/24/outline";
import { formatNumber } from "./in-app-survey-analytics-utils";

interface Props {
  label: string;
  value: number;
  suffix?: string;
  denominator?: string;
  delta: number;
  deltaSuffix?: string;
}

const InAppSurveyMetricCard = ({
  label,
  value,
  suffix = "",
  denominator,
  delta,
  deltaSuffix = "%",
}: Props) => {
  const positive = delta >= 0;

  return (
    <div className="rounded-2xl border border-slate-200 bg-white p-5 shadow-sm">
      <div className="text-sm font-medium text-slate-500">{label}</div>
      <div className="mt-4 flex items-end gap-1">
        <span className="text-4xl font-bold tracking-normal text-slate-950">
          {formatNumber(value)}
          {suffix}
        </span>
        {denominator ? (
          <span className="mb-1 text-xl font-semibold text-slate-400">
            / {denominator}
          </span>
        ) : null}
      </div>
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
        {positive ? "+" : ""}
        {delta}
        {deltaSuffix} vs prev. period
      </div>
    </div>
  );
};

export default InAppSurveyMetricCard;
