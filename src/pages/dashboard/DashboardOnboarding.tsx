import React from "react";
import { ArrowTrendingDownIcon } from "@heroicons/react/24/outline";

import DashboardShell from "../../components/dashboard/DashboardShell";
import StatCard, { DeltaBadge } from "../../components/dashboard/StatCard";
import { labelForStep } from "../../components/dashboard/onboardingStepLabels";
import {
  SERIES,
  formatNumber,
  formatPercent,
} from "../../components/dashboard/dashboardTheme";
import {
  useDashboardData,
  useDashboardFilters,
} from "../../components/dashboard/useDashboard";
import { dashboardService } from "../../services/dashboardService";
import { IFunnelStep } from "../../types/interface/dashboard.interface";

/**
 * One funnel step.
 *
 * Drawn as HTML rather than a chart library: a funnel's job is to show where
 * people are lost, and that reads best as a labelled row — bar width for shape,
 * the count and the loss spelled out beside it.
 */
const FunnelRow: React.FC<{
  step: IFunnelStep;
  first: number;
  isBiggestDrop: boolean;
}> = ({ step, first, isBiggestDrop }) => {
  const width = first ? Math.max((step.users / first) * 100, 2) : 0;

  return (
    <li className="space-y-1">
      <div className="flex items-baseline justify-between gap-3 text-sm">
        <span className="truncate font-medium text-gray-800">
          {labelForStep(step.event)}
        </span>
        <span className="shrink-0 tabular-nums text-gray-900">
          {formatNumber(step.users)}
          <span className="ml-1.5 text-xs font-normal text-gray-500">
            {formatPercent(step.passRate)}
          </span>
        </span>
      </div>
      <div className="flex items-center gap-2">
        <div className="h-2.5 flex-1 overflow-hidden rounded-full bg-gray-100">
          <div
            className="h-full rounded-full"
            style={{ width: `${width}%`, backgroundColor: SERIES.active }}
          />
        </div>
        {step.dropUsers > 0 && (
          <span
            className={`shrink-0 rounded-full px-2 py-0.5 text-[11px] font-medium ${
              isBiggestDrop
                ? "bg-rose-50 text-rose-700"
                : "bg-gray-100 text-gray-500"
            }`}
            title="So với bước liền trước"
          >
            −{formatNumber(step.dropUsers)} ({formatPercent(step.dropRate)})
          </span>
        )}
      </div>
    </li>
  );
};

const DashboardOnboarding: React.FC = () => {
  const { filters, setFilters, applyPreset, activePreset, query } =
    useDashboardFilters();
  const { data, loading, error, reload } = useDashboardData(
    dashboardService.getOnboarding,
    query
  );

  const first = data?.steps[0]?.users ?? 0;

  return (
    <DashboardShell
      title="Onboarding"
      subtitle="Người mới đi hết luồng làm quen tới đâu, và rớt ở màn nào."
      filters={filters}
      activePreset={activePreset}
      onPreset={applyPreset}
      onChange={setFilters}
      range={data?.range}
      compareRange={data?.compareRange}
      loading={loading}
      error={error}
      hasData={Boolean(data)}
      isEmpty={Boolean(data && data.started === 0)}
      onReload={reload}
    >
      {data && (
        <div className="space-y-4">
          <div className="grid grid-cols-1 gap-4 sm:grid-cols-2 lg:grid-cols-4">
            <StatCard
              label="Bắt đầu onboarding"
              value={formatNumber(data.started)}
              hint="Người dùng chạm ít nhất 1 màn onboarding"
              delta={
                <DeltaBadge
                  current={data.started}
                  previous={data.previous?.started}
                />
              }
            />
            <StatCard
              label="Hoàn tất"
              value={formatNumber(data.completed)}
              hint="Tới được màn hoàn tất"
              delta={
                <DeltaBadge
                  current={data.completed}
                  previous={data.previous?.completed}
                />
              }
            />
            <StatCard
              label="Tỷ lệ hoàn tất"
              value={formatPercent(data.completionRate)}
              hint={
                data.previous?.completionRate != null
                  ? `Kỳ trước: ${formatPercent(data.previous.completionRate)}`
                  : undefined
              }
            />
            <StatCard
              label="Rớt nhiều nhất"
              value={
                data.biggestDrop ? labelForStep(data.biggestDrop.event) : "—"
              }
              hint={
                data.biggestDrop
                  ? `Mất ${formatNumber(
                      data.biggestDrop.dropUsers
                    )} người (${formatPercent(data.biggestDrop.dropRate)})`
                  : "Không có bước nào mất người"
              }
              icon={<ArrowTrendingDownIcon className="h-5 w-5" />}
            />
          </div>

          <section className="rounded-xl border border-gray-200 bg-white p-4 shadow-sm">
            <h2 className="text-sm font-semibold text-gray-900">
              Phễu theo từng màn
            </h2>
            <p className="mt-0.5 text-xs text-gray-500">
              Đếm số người khác nhau chạm từng màn. Thứ tự suy ra từ số người
              còn lại, nên màn mới thêm vào luồng tự xuất hiện ở đây mà không
              cần deploy API.
            </p>
            <ol className="mt-4 space-y-3">
              {data.steps.map((step) => (
                <FunnelRow
                  key={step.event}
                  step={step}
                  first={first}
                  isBiggestDrop={data.biggestDrop?.event === step.event}
                />
              ))}
            </ol>
          </section>
        </div>
      )}
    </DashboardShell>
  );
};

export default DashboardOnboarding;
