import React from "react";
import {
  Bar,
  BarChart,
  CartesianGrid,
  Cell,
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
import {
  AXIS_PROPS,
  GRID_PROPS,
  SERIES,
  formatDayTick,
  formatDuration,
  formatHour,
  formatNumber,
  formatPercent,
} from "../../components/dashboard/dashboardTheme";
import {
  useDashboardData,
  useDashboardFilters,
} from "../../components/dashboard/useDashboard";
import { dashboardService } from "../../services/dashboardService";

const bucketLabel = (from: number, to: number | null) =>
  to === null ? `${from}+` : from === to ? `${from}` : `${from}–${to}`;

const DashboardSessions: React.FC = () => {
  const { filters, setFilters, applyPreset, activePreset, query } =
    useDashboardFilters();
  const { data, loading, error, reload } = useDashboardData(
    dashboardService.getSessions,
    query
  );

  const peakHour = data
    ? [...data.hourly].sort((a, b) => b.events - a.events)[0]?.hour
    : undefined;

  return (
    <DashboardShell
      title="Phiên & Tương tác"
      subtitle="Người dùng mở app bao nhiêu lần, ở lại bao lâu, và vào giờ nào."
      filters={filters}
      activePreset={activePreset}
      onPreset={applyPreset}
      onChange={setFilters}
      range={data?.range}
      compareRange={data?.compareRange}
      loading={loading}
      error={error}
      hasData={Boolean(data)}
      isEmpty={Boolean(data && data.totals.sessions === 0)}
      onReload={reload}
    >
      {data && (
        <div className="space-y-4">
          <div className="grid grid-cols-1 gap-4 sm:grid-cols-2 lg:grid-cols-4">
            <StatCard
              label="Phiên truy cập"
              value={formatNumber(data.totals.sessions)}
              hint="Cắt phiên theo khoảng nghỉ 30 phút"
              delta={
                <DeltaBadge
                  current={data.totals.sessions}
                  previous={data.previousTotals?.sessions}
                />
              }
            />
            <StatCard
              label="Phiên có tương tác"
              value={formatPercent(data.totals.engagementRate)}
              hint={`${formatNumber(
                data.totals.engagedSessions
              )} phiên ≥10 giây hoặc ≥2 màn`}
            />
            <StatCard
              label="Thời lượng trung bình"
              value={formatDuration(data.totals.avgDurationMs)}
              hint={`${data.totals.avgEvents} sự kiện · ${data.totals.avgScreens} màn mỗi phiên`}
            />
            <StatCard
              label="Phiên / người dùng"
              value={
                data.totals.sessionsPerUser === null
                  ? "—"
                  : String(data.totals.sessionsPerUser)
              }
              hint={`${formatNumber(data.totals.activeUsers)} người hoạt động`}
            />
          </div>

          <ChartCard
            title="Phiên theo ngày"
            description="Tổng số phiên và phần có tương tác thật."
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
                  dataKey="sessions"
                  name="Tổng phiên"
                  stroke={SERIES.active}
                  strokeWidth={2}
                  dot={false}
                  activeDot={{ r: 4 }}
                />
                <Line
                  type="monotone"
                  dataKey="engagedSessions"
                  name="Có tương tác"
                  stroke={SERIES.engaged}
                  strokeWidth={2}
                  dot={false}
                  activeDot={{ r: 4 }}
                />
              </LineChart>
            </ResponsiveContainer>
          </ChartCard>

          <div className="grid grid-cols-1 gap-4 lg:grid-cols-2">
            <ChartCard
              title="Khung giờ vàng"
              description={
                peakHour === undefined
                  ? "Sự kiện theo giờ trong ngày (giờ Việt Nam)."
                  : `Cao điểm lúc ${formatHour(
                      peakHour
                    )} — giờ tốt nhất để đẩy thông báo nhắc học.`
              }
            >
              <ResponsiveContainer width="100%" height="100%">
                <BarChart
                  data={data.hourly}
                  margin={{ top: 8, right: 16, bottom: 0, left: -12 }}
                >
                  <CartesianGrid {...GRID_PROPS} />
                  <XAxis
                    dataKey="hour"
                    tickFormatter={(hour) => formatHour(Number(hour))}
                    interval={1}
                    {...AXIS_PROPS}
                  />
                  <YAxis allowDecimals={false} {...AXIS_PROPS} />
                  <Tooltip
                    cursor={{ fill: "rgba(148, 163, 184, 0.12)" }}
                    content={
                      <ChartTooltip
                        labelFormatter={(label) => formatHour(Number(label))}
                      />
                    }
                  />
                  <Bar
                    dataKey="events"
                    name="Sự kiện"
                    radius={[4, 4, 0, 0]}
                    fill={SERIES.active}
                  >
                    {/* The peak hour is what the reader is looking for, so it
                        is the one mark that stands out — same hue, full
                        strength, while the rest recede. */}
                    {data.hourly.map((point) => (
                      <Cell
                        key={point.hour}
                        fill={SERIES.active}
                        fillOpacity={point.hour === peakHour ? 1 : 0.45}
                      />
                    ))}
                  </Bar>
                </BarChart>
              </ResponsiveContainer>
            </ChartCard>

            <ChartCard
              title="Độ sâu mỗi phiên"
              description="Số sự kiện trong một phiên — phiên 1 sự kiện là mở rồi thoát ngay."
            >
              <ResponsiveContainer width="100%" height="100%">
                <BarChart
                  data={data.depthBuckets.map((bucket) => ({
                    ...bucket,
                    label: bucketLabel(bucket.from, bucket.to),
                  }))}
                  margin={{ top: 8, right: 16, bottom: 0, left: -12 }}
                >
                  <CartesianGrid {...GRID_PROPS} />
                  <XAxis dataKey="label" {...AXIS_PROPS} />
                  <YAxis allowDecimals={false} {...AXIS_PROPS} />
                  <Tooltip
                    cursor={{ fill: "rgba(148, 163, 184, 0.12)" }}
                    content={
                      <ChartTooltip
                        labelFormatter={(label) => `${label} sự kiện`}
                      />
                    }
                  />
                  <Bar
                    dataKey="sessions"
                    name="Phiên"
                    radius={[4, 4, 0, 0]}
                    fill={SERIES.new}
                  />
                </BarChart>
              </ResponsiveContainer>
            </ChartCard>
          </div>
        </div>
      )}
    </DashboardShell>
  );
};

export default DashboardSessions;
