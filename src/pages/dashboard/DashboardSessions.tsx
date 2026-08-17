import React, { useState } from "react";
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

import ActivityHeatmap from "../../components/dashboard/ActivityHeatmap";
import ChartCard from "../../components/dashboard/ChartCard";
import DurationBarList from "../../components/dashboard/DurationBarList";
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

// Mongo's `$dayOfWeek`: 1 = Sunday.
const WEEKDAY_LABELS: Record<number, string> = {
  1: "Chủ nhật",
  2: "Thứ 2",
  3: "Thứ 3",
  4: "Thứ 4",
  5: "Thứ 5",
  6: "Thứ 6",
  7: "Thứ 7",
};

const HEATMAP_MODES = [
  { key: "all" as const, label: "Hoạt động chung" },
  { key: "learning" as const, label: "Học bài" },
];

const DashboardSessions: React.FC = () => {
  const { filters, setFilters, applyPreset, activePreset, query } =
    useDashboardFilters();
  const { data, loading, error, reload } = useDashboardData(
    dashboardService.getSessions,
    query
  );
  const [heatmapMode, setHeatmapMode] = useState<"all" | "learning">("all");

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

          <section className="space-y-3">
            <h2 className="text-[11px] font-semibold uppercase tracking-wider text-gray-400">
              Một phiên kéo dài bao lâu
            </h2>
            <div className="grid grid-cols-1 gap-4 sm:grid-cols-2 lg:grid-cols-4">
              <StatCard
                label="Thời lượng điển hình"
                value={formatDuration(data.durations.medianMs)}
                hint="Trung vị — nửa số phiên ngắn hơn mức này"
              />
              <StatCard
                label="Nửa giữa số phiên (50%)"
                value={`${formatDuration(
                  data.durations.p25Ms
                )} – ${formatDuration(data.durations.p75Ms)}`}
                hint="Khoảng P25–P75. Càng rộng thì hành vi càng chênh lệch"
              />
              <StatCard
                label="Thời gian thao tác thật"
                value={formatDuration(data.durations.engagedMedianMs)}
                hint="Trung vị của riêng phiên có tương tác"
              />
              <StatCard
                label="Phiên dài (>20 phút)"
                value={formatPercent(data.durations.longSessionRate)}
                hint={`Ngược lại, ${formatPercent(
                  data.durations.bounceRate
                )} phiên chỉ ghé dưới 30 giây`}
              />
            </div>
          </section>

          <div className="grid grid-cols-1 gap-4 lg:grid-cols-2">
            <section className="rounded-xl border border-gray-200 bg-white p-4 shadow-sm">
              <h2 className="text-sm font-semibold text-gray-900">
                Thứ nào phiên dài nhất
              </h2>
              <p className="mb-3 mt-0.5 text-xs text-gray-500">
                Trung vị thời lượng phiên theo thứ trong tuần. Di chuột vào
                thanh để xem số phiên đứng sau con số.
              </p>
              <DurationBarList
                rows={[...data.byWeekday]
                  .sort((a, b) => (b.medianMs ?? 0) - (a.medianMs ?? 0))
                  .map((row) => ({
                    label: WEEKDAY_LABELS[row.weekday] ?? String(row.weekday),
                    ms: row.medianMs,
                    sessions: row.sessions,
                  }))}
              />
            </section>

            <section className="rounded-xl border border-gray-200 bg-white p-4 shadow-sm">
              <h2 className="text-sm font-semibold text-gray-900">
                Thời lượng phiên theo bản app
              </h2>
              <p className="mb-3 mt-0.5 text-xs text-gray-500">
                Trung vị một phiên kéo dài bao lâu, so giữa các bản app. Bản vừa
                phát hành thường ít phiên nên đọc kèm số phiên trong tooltip.
              </p>
              <DurationBarList
                rows={data.byAppVersion.map((row) => ({
                  label: row.appVersion,
                  ms: row.medianMs,
                  sessions: row.sessions,
                }))}
                color={SERIES.new}
              />
            </section>
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

          <section className="rounded-xl border border-gray-200 bg-white p-4 shadow-sm">
            <div className="flex flex-wrap items-start justify-between gap-3">
              <div>
                <h2 className="text-sm font-semibold text-gray-900">
                  Số người hoạt động theo giờ &amp; thứ trong tuần
                </h2>
                <p className="mt-0.5 text-xs text-gray-500">
                  Ô càng đậm = càng đông người dùng hoạt động vào khung giờ đó.
                  Di chuột vào ô để xem số cụ thể.
                </p>
              </div>
              <div
                className="flex items-center gap-1"
                role="group"
                aria-label="Chế độ heatmap"
              >
                {HEATMAP_MODES.map((mode) => (
                  <button
                    key={mode.key}
                    type="button"
                    onClick={() => setHeatmapMode(mode.key)}
                    aria-pressed={heatmapMode === mode.key}
                    className={`h-8 rounded-lg px-3 text-xs font-medium transition-colors ${
                      heatmapMode === mode.key
                        ? "bg-blue-500 text-white"
                        : "border border-gray-300 bg-white text-gray-700 hover:bg-gray-50"
                    }`}
                  >
                    {mode.label}
                  </button>
                ))}
              </div>
            </div>
            <div className="mt-4">
              <ActivityHeatmap cells={data.heatmap[heatmapMode]} />
            </div>
          </section>
        </div>
      )}
    </DashboardShell>
  );
};

export default DashboardSessions;
