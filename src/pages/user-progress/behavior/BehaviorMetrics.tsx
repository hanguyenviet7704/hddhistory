import React from "react";
import { IUserBehaviorSummary } from "../../../types/interface/analytics.interface";
import { formatDateTime, formatDuration } from "./behaviorFormat";

const Metric = ({
  label,
  value,
  hint,
}: {
  label: string;
  value: string;
  hint?: string;
}) => (
  <div className="rounded-lg border border-gray-200 bg-white px-3 py-2">
    <div className="text-[11px] uppercase tracking-wide text-gray-400">
      {label}
    </div>
    <div className="text-lg font-semibold text-gray-900 leading-tight">
      {value}
    </div>
    {hint ? (
      <div className="text-xs text-gray-500 truncate" title={hint}>
        {hint}
      </div>
    ) : null}
  </div>
);

export default function BehaviorMetrics({
  summary,
}: {
  summary: IUserBehaviorSummary;
}) {
  return (
    <div className="grid grid-cols-2 md:grid-cols-3 xl:grid-cols-6 gap-2">
      <Metric label="Ngày active" value={String(summary.activeDays ?? 0)} />
      <Metric label="Session" value={String(summary.sessions ?? 0)} />
      <Metric
        label="Tổng thời lượng"
        value={formatDuration(summary.totalDurationMs)}
      />
      <Metric
        label="TB mỗi session"
        value={formatDuration(summary.avgSessionMs)}
      />
      <Metric label="Tổng event" value={String(summary.totalEvents ?? 0)} />
      <Metric
        label="Hoạt động cuối"
        value={formatDateTime(summary.lastActiveAt)}
        hint={[
          summary.platforms?.join(", "),
          summary.appVersions?.length
            ? `v${summary.appVersions.join(", v")}`
            : "",
        ]
          .filter(Boolean)
          .join(" · ")}
      />
    </div>
  );
}
