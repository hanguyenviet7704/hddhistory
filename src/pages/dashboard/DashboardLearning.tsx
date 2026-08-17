import React from "react";
import { Link, useLocation } from "react-router-dom";
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
} from "../../components/dashboard/dashboardTheme";
import {
  useDashboardData,
  useDashboardFilters,
} from "../../components/dashboard/useDashboard";
import { dashboardService } from "../../services/dashboardService";

const DashboardLearning: React.FC = () => {
  const { filters, setFilters, applyPreset, activePreset, query } =
    useDashboardFilters();
  const { data, loading, error, reload } = useDashboardData(
    dashboardService.getLearning,
    query
  );
  const { search } = useLocation();

  return (
    <DashboardShell
      title="Hành vi học"
      subtitle="Từ mở lộ trình tới hoàn thành bài, và nội dung nào được học nhiều nhất."
      filters={filters}
      activePreset={activePreset}
      onPreset={applyPreset}
      onChange={setFilters}
      range={data?.range}
      compareRange={data?.compareRange}
      loading={loading}
      error={error}
      hasData={Boolean(data)}
      isEmpty={Boolean(
        data && data.milestones.every((milestone) => milestone.users === 0)
      )}
      onReload={reload}
    >
      {data && (
        <div className="space-y-4">
          <div className="grid grid-cols-1 gap-4 sm:grid-cols-2 lg:grid-cols-4">
            {data.milestones.map((milestone) => (
              <StatCard
                key={milestone.key}
                label={milestone.label}
                value={formatNumber(milestone.users)}
                hint={`${formatNumber(milestone.events)} lượt`}
                delta={
                  <DeltaBadge
                    current={milestone.users}
                    previous={milestone.previousUsers}
                  />
                }
              />
            ))}
          </div>

          <ChartCard
            title="Hoàn thành theo ngày"
            description="Số người khác nhau hoàn thành keypoint và hoàn thành bài."
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
                  dataKey="keypointCompleted"
                  name="Hoàn thành keypoint"
                  stroke={SERIES.active}
                  strokeWidth={2}
                  dot={false}
                  activeDot={{ r: 4 }}
                />
                <Line
                  type="monotone"
                  dataKey="lessonCompleted"
                  name="Hoàn thành bài"
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
              <div className="flex items-center justify-between gap-2">
                <h2 className="text-sm font-semibold text-gray-900">
                  Khoá được học nhiều nhất
                </h2>
                <Link
                  to={`/statistics${search}`}
                  className="text-xs font-medium text-blue-600 hover:underline"
                >
                  Tiến trình khoá →
                </Link>
              </div>
              <p className="mb-3 mt-0.5 text-xs text-gray-500">
                Theo số người khác nhau có sự kiện gắn với khoá đó.
              </p>
              <TopList rows={data.topCourses} measureLabel="Người học" />
            </section>

            <section className="rounded-xl border border-gray-200 bg-white p-4 shadow-sm">
              <h2 className="text-sm font-semibold text-gray-900">
                Nhóm kỹ năng dẫn đầu
              </h2>
              <p className="mb-3 mt-0.5 text-xs text-gray-500">
                Skillset mà người dùng chạm vào nhiều nhất trong kỳ.
              </p>
              <TopList
                rows={data.topSkills}
                measureLabel="Người học"
                color={SERIES.new}
              />
            </section>
          </div>
        </div>
      )}
    </DashboardShell>
  );
};

export default DashboardLearning;
