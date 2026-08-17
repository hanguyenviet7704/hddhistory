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

import ChartCard from "../../components/dashboard/ChartCard";
import ChartTooltip from "../../components/dashboard/ChartTooltip";
import DashboardShell from "../../components/dashboard/DashboardShell";
import StatCard, { DeltaBadge } from "../../components/dashboard/StatCard";
import TopList from "../../components/dashboard/TopList";
import {
  AXIS_PROPS,
  GRID_PROPS,
  SERIES,
  formatDayTick,
  formatNumber,
  formatPercent,
} from "../../components/dashboard/dashboardTheme";
import {
  useDashboardData,
  useDashboardFilters,
} from "../../components/dashboard/useDashboard";
import { dashboardService } from "../../services/dashboardService";
import { IRetentionPoint } from "../../types/interface/dashboard.interface";

const findOffset = (points: IRetentionPoint[], offset: number) =>
  points.find((point) => point.offset === offset) ?? null;

/**
 * A retention cell that refuses to lie: a cohort too young to have reached its
 * D+N day shows "chưa đủ dữ liệu", never 0%.
 */
const RetentionCell: React.FC<{ point: IRetentionPoint | null }> = ({
  point,
}) => {
  if (!point || point.cohortUsers === 0) {
    return <span className="text-xs text-gray-400">chưa đủ dữ liệu</span>;
  }

  return (
    <span className="text-sm font-medium text-gray-900">
      {formatPercent(point.rate)}
      <span className="ml-1 text-xs font-normal text-gray-500">
        ({formatNumber(point.retainedUsers)}/{formatNumber(point.cohortUsers)})
      </span>
    </span>
  );
};

const DashboardUsers: React.FC = () => {
  const { filters, setFilters, applyPreset, activePreset, query } =
    useDashboardFilters();
  const { data, loading, error, reload } = useDashboardData(
    dashboardService.getUsers,
    query
  );

  const d1 = data ? findOffset(data.retention, 1) : null;
  const d7 = data ? findOffset(data.retention, 7) : null;

  return (
    <DashboardShell
      title="Người dùng & Giữ chân"
      subtitle="Ai đang dùng app, ai mới đến, và bao nhiêu người quay lại."
      filters={filters}
      activePreset={activePreset}
      onPreset={applyPreset}
      onChange={setFilters}
      appVersions={data?.byAppVersion.map((row) => row.name)}
      range={data?.range}
      compareRange={data?.compareRange}
      loading={loading}
      error={error}
      hasData={Boolean(data)}
      isEmpty={Boolean(data && data.totals.active === 0 && data.totals.new === 0)}
      onReload={reload}
    >
      {data && (
        <div className="space-y-4">
          <div className="grid grid-cols-1 gap-4 sm:grid-cols-2 lg:grid-cols-5">
            <StatCard
              label="User hoạt động"
              value={formatNumber(data.totals.active)}
              hint="Có ít nhất 1 sự kiện trong kỳ"
              delta={
                <DeltaBadge
                  current={data.totals.active}
                  previous={data.previousTotals?.active}
                />
              }
            />
            <StatCard
              label="Người mới"
              value={formatNumber(data.totals.new)}
              hint="Tài khoản tạo trong kỳ"
              delta={
                <DeltaBadge
                  current={data.totals.new}
                  previous={data.previousTotals?.new}
                />
              }
            />
            <StatCard
              label="Người quay lại"
              value={formatNumber(data.totals.returning)}
              hint="Hoạt động nhưng không phải người mới"
              delta={
                <DeltaBadge
                  current={data.totals.returning}
                  previous={data.previousTotals?.returning}
                />
              }
            />
            <StatCard
              label="Quay lại sau ngày 1"
              value={formatPercent(d1?.rate)}
              hint={
                d1?.cohortUsers
                  ? `${formatNumber(d1.retainedUsers)}/${formatNumber(
                      d1.cohortUsers
                    )} người đăng ký`
                  : "Chưa có cohort đủ tuổi"
              }
            />
            <StatCard
              label="Quay lại sau 7 ngày"
              value={formatPercent(d7?.rate)}
              hint={
                d7?.cohortUsers
                  ? `${formatNumber(d7.retainedUsers)}/${formatNumber(
                      d7.cohortUsers
                    )} người đăng ký`
                  : "Chưa có cohort đủ tuổi"
              }
            />
          </div>

          <ChartCard
            title="Người dùng theo ngày"
            description="Người hoạt động so với người mới đăng ký."
            height={300}
          >
            <ResponsiveContainer width="100%" height="100%">
              <LineChart
                data={data.daily}
                margin={{ top: 8, right: 16, bottom: 0, left: -12 }}
              >
                <CartesianGrid {...GRID_PROPS} />
                <XAxis
                  dataKey="date"
                  tickFormatter={formatDayTick}
                  {...AXIS_PROPS}
                />
                <YAxis allowDecimals={false} {...AXIS_PROPS} />
                <Tooltip
                  content={
                    <ChartTooltip
                      labelFormatter={(label) => formatDayTick(String(label))}
                    />
                  }
                />
                <Legend
                  iconType="plainline"
                  wrapperStyle={{ fontSize: 12, paddingTop: 8 }}
                />
                <Line
                  type="monotone"
                  dataKey="active"
                  name="Hoạt động"
                  stroke={SERIES.active}
                  strokeWidth={2}
                  dot={false}
                  activeDot={{ r: 4 }}
                />
                <Line
                  type="monotone"
                  dataKey="new"
                  name="Người mới"
                  stroke={SERIES.new}
                  strokeWidth={2}
                  dot={false}
                  activeDot={{ r: 4 }}
                />
              </LineChart>
            </ResponsiveContainer>
          </ChartCard>

          <div className="grid grid-cols-1 gap-4 lg:grid-cols-2">
            <section className="rounded-xl border border-gray-200 bg-white p-4 shadow-sm">
              <h2 className="text-sm font-semibold text-gray-900">
                Giữ chân theo bản app
              </h2>
              <p className="mt-0.5 text-xs text-gray-500">
                Theo bản app người dùng gặp lần đầu. Bản vừa phát hành sẽ chưa
                có số D7 cho tới khi cohort đủ 7 ngày.
              </p>
              <div className="mt-3 overflow-x-auto">
                <table className="w-full text-left text-sm">
                  <thead>
                    <tr className="border-b border-gray-200 text-[11px] uppercase tracking-wide text-gray-400">
                      <th className="py-2 pr-3 font-medium">Bản app</th>
                      <th className="py-2 pr-3 font-medium">Sau ngày 1</th>
                      <th className="py-2 font-medium">Sau 7 ngày</th>
                    </tr>
                  </thead>
                  <tbody>
                    {data.retentionByAppVersion.length === 0 && (
                      <tr>
                        <td
                          colSpan={3}
                          className="py-6 text-center text-sm text-gray-500"
                        >
                          Chưa có cohort nào trong kỳ
                        </td>
                      </tr>
                    )}
                    {data.retentionByAppVersion.map((row) => (
                      <tr
                        key={row.appVersion}
                        className="border-b border-gray-100 last:border-0"
                      >
                        <td className="py-2 pr-3 font-medium text-gray-800">
                          {row.appVersion}
                        </td>
                        <td className="py-2 pr-3">
                          <RetentionCell point={findOffset(row.points, 1)} />
                        </td>
                        <td className="py-2">
                          <RetentionCell point={findOffset(row.points, 7)} />
                        </td>
                      </tr>
                    ))}
                  </tbody>
                </table>
              </div>
            </section>

            <div className="grid grid-cols-1 gap-4 sm:grid-cols-2 lg:grid-cols-1">
              <section className="rounded-xl border border-gray-200 bg-white p-4 shadow-sm">
                <h2 className="mb-3 text-sm font-semibold text-gray-900">
                  Theo nền tảng
                </h2>
                <TopList
                  rows={data.byPlatform.map((row) => ({
                    name: row.name,
                    users: row.value,
                  }))}
                />
              </section>
              <section className="rounded-xl border border-gray-200 bg-white p-4 shadow-sm">
                <h2 className="mb-3 text-sm font-semibold text-gray-900">
                  Theo bản app
                </h2>
                <TopList
                  rows={data.byAppVersion.map((row) => ({
                    name: row.name,
                    users: row.value,
                  }))}
                  color={SERIES.new}
                />
              </section>
            </div>
          </div>
        </div>
      )}
    </DashboardShell>
  );
};

export default DashboardUsers;
