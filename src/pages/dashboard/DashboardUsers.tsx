import React, { useMemo, useState } from "react";
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
import RetentionCurve, {
  RetentionSeries,
} from "../../components/dashboard/RetentionCurve";
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
import {
  IRetentionPoint,
  IUsersPage,
} from "../../types/interface/dashboard.interface";

const findOffset = (points: IRetentionPoint[], offset: number) =>
  points.find((point) => point.offset === offset) ?? null;

const PLATFORM_LABELS: Record<string, string> = {
  ios: "iOS",
  android: "Android",
};

const RETENTION_TABS = [
  { key: "all" as const, label: "Chung (tất cả)" },
  { key: "platform" as const, label: "Theo nền tảng" },
  { key: "version" as const, label: "Theo bản app" },
];

/** Stickiness under this reads as a base that opens the app rarely. */
const HEALTHY_STICKINESS = 0.2;

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

/** Pivots the flat platform rows into one chart row per day. */
const usePlatformSeries = (data: IUsersPage | null) =>
  useMemo(() => {
    if (!data) return { rows: [], platforms: [] as string[] };

    const platforms = Array.from(
      new Set(data.dailyByPlatform.map((row) => row.platform))
    ).sort();

    const byDate = new Map<string, Record<string, number | string>>();
    for (const row of data.dailyByPlatform) {
      const entry = byDate.get(row.date) ?? { date: row.date };
      entry[row.platform] = row.users;
      byDate.set(row.date, entry);
    }

    return {
      rows: Array.from(byDate.values()).sort((a, b) =>
        String(a.date).localeCompare(String(b.date))
      ),
      platforms,
    };
  }, [data]);

const DashboardUsers: React.FC = () => {
  const { filters, setFilters, applyPreset, activePreset, query } =
    useDashboardFilters();
  const { data, loading, error, reload } = useDashboardData(
    dashboardService.getUsers,
    query
  );
  const [retentionTab, setRetentionTab] =
    useState<(typeof RETENTION_TABS)[number]["key"]>("all");

  const { rows: platformRows, platforms } = usePlatformSeries(data);

  const d1 = data ? findOffset(data.retention, 1) : null;
  const d7 = data ? findOffset(data.retention, 7) : null;

  const retentionSeries: RetentionSeries[] = useMemo(() => {
    if (!data) return [];

    if (retentionTab === "platform") {
      return data.retentionByPlatform.map((row) => ({
        key: row.platform,
        label: PLATFORM_LABELS[row.platform] ?? row.platform,
        points: row.points,
      }));
    }

    if (retentionTab === "version") {
      // Three at most: the palette has three fixed slots and inventing a fourth
      // hue is what breaks colour-blind separation. Newest versions win.
      return data.retentionByAppVersion.slice(0, 3).map((row) => ({
        key: row.appVersion,
        label: row.appVersion,
        points: row.points,
      }));
    }

    return [{ key: "all", label: "Chung tất cả", points: data.retention }];
  }, [data, retentionTab]);

  const mauGrowth =
    data && data.activeWindows.mauAtStart > 0
      ? (data.activeWindows.mau - data.activeWindows.mauAtStart) /
        data.activeWindows.mauAtStart
      : null;

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

          <section className="space-y-3">
            <h2 className="text-[11px] font-semibold uppercase tracking-wider text-gray-400">
              Người dùng hoạt động theo ngày
            </h2>
            <div className="grid grid-cols-1 gap-4 lg:grid-cols-3">
              <div className="lg:col-span-2">
                <ChartCard
                  title="Người dùng hoạt động mỗi ngày (DAU)"
                  description="Số người mở app trong ngày, tách theo nền tảng."
                  height={300}
                >
                  <ResponsiveContainer width="100%" height="100%">
                    <LineChart
                      data={platformRows}
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
                            labelFormatter={(label) =>
                              formatDayTick(String(label))
                            }
                          />
                        }
                      />
                      <Legend
                        iconType="plainline"
                        wrapperStyle={{ fontSize: 12, paddingTop: 8 }}
                      />
                      {platforms.slice(0, 3).map((platform, index) => (
                        <Line
                          key={platform}
                          type="monotone"
                          dataKey={platform}
                          name={PLATFORM_LABELS[platform] ?? platform}
                          stroke={
                            [SERIES.active, SERIES.new, SERIES.engaged][index]
                          }
                          strokeWidth={2}
                          dot={false}
                          activeDot={{ r: 4 }}
                        />
                      ))}
                    </LineChart>
                  </ResponsiveContainer>
                </ChartCard>
              </div>

              <div className="space-y-4">
                <StatCard
                  label="MAU · người dùng 28 ngày"
                  value={formatNumber(data.activeWindows.mau)}
                  hint={`Đầu kỳ ${formatNumber(data.activeWindows.mauAtStart)}`}
                  delta={
                    mauGrowth === null ? undefined : (
                      <DeltaBadge
                        current={data.activeWindows.mau}
                        previous={data.activeWindows.mauAtStart}
                      />
                    )
                  }
                />
                <StatCard
                  label="WAU · người dùng 7 ngày"
                  value={formatNumber(data.activeWindows.wau)}
                  hint={`Đo tại ngày ${data.activeWindows.dauDate}`}
                />
                <StatCard
                  label="Độ dính (DAU/MAU)"
                  value={formatPercent(data.activeWindows.stickiness)}
                  hint={`DAU ${formatNumber(
                    data.activeWindows.dau
                  )} / MAU ${formatNumber(
                    data.activeWindows.mau
                  )} · mốc tốt >${Math.round(HEALTHY_STICKINESS * 100)}%`}
                />
              </div>
            </div>
          </section>

          <section className="rounded-xl border border-gray-200 bg-white p-4 shadow-sm">
            <div className="flex flex-wrap items-start justify-between gap-3">
              <div>
                <h2 className="text-sm font-semibold text-gray-900">
                  Tỷ lệ quay lại theo ngày kể từ khi đăng ký
                </h2>
                <p className="mt-0.5 text-xs text-gray-500">
                  Trong nhóm người đăng ký trong kỳ, bao nhiêu % có hoạt động
                  đúng ngày thứ 1, 2, 3, 7, 14. Đường đứt quãng nghĩa là cohort
                  chưa đủ tuổi để đo mốc đó.
                </p>
              </div>
              <div
                className="flex items-center gap-1"
                role="group"
                aria-label="Cách tách retention"
              >
                {RETENTION_TABS.map((tab) => (
                  <button
                    key={tab.key}
                    type="button"
                    onClick={() => setRetentionTab(tab.key)}
                    aria-pressed={retentionTab === tab.key}
                    className={`h-8 rounded-lg px-3 text-xs font-medium transition-colors ${
                      retentionTab === tab.key
                        ? "bg-blue-500 text-white"
                        : "border border-gray-300 bg-white text-gray-700 hover:bg-gray-50"
                    }`}
                  >
                    {tab.label}
                  </button>
                ))}
              </div>
            </div>
            <div className="mt-4" style={{ height: 300 }}>
              {retentionSeries.length ? (
                <RetentionCurve series={retentionSeries} />
              ) : (
                <p className="py-16 text-center text-sm text-gray-500">
                  Chưa có cohort nào trong kỳ để tách theo chiều này
                </p>
              )}
            </div>
          </section>

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
                    name: PLATFORM_LABELS[row.name] ?? row.name,
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

          <section className="space-y-3">
            <h2 className="text-[11px] font-semibold uppercase tracking-wider text-gray-400">
              Người dùng đến từ đâu &amp; là ai
            </h2>
            <div className="grid grid-cols-1 gap-4 lg:grid-cols-2">
              <section className="rounded-xl border border-gray-200 bg-white p-4 shadow-sm">
                <h2 className="text-sm font-semibold text-gray-900">Quốc gia</h2>
                <p className="mb-3 mt-0.5 text-xs text-gray-500">
                  Theo số người đăng ký trong kỳ.
                </p>
                {data.demographics.hasCountryData ? (
                  <TopList
                    rows={data.demographics.byCountry.map((row) => ({
                      name: row.name,
                      users: row.value,
                    }))}
                    measureLabel="Người dùng"
                  />
                ) : (
                  <p className="py-8 text-center text-sm text-gray-500">
                    App chưa gửi quốc gia về server, nên chỗ này không có dữ
                    liệu — không phải lỗi tải.
                  </p>
                )}
              </section>

              <section className="rounded-xl border border-gray-200 bg-white p-4 shadow-sm">
                <h2 className="text-sm font-semibold text-gray-900">Độ tuổi</h2>
                <p className="mb-3 mt-0.5 text-xs text-gray-500">
                  Người dùng tự khai khi làm onboarding.
                </p>
                {data.demographics.hasAgeData ? (
                  <TopList
                    rows={data.demographics.byAge.map((row) => ({
                      name: row.name,
                      users: row.value,
                    }))}
                    measureLabel="Người dùng"
                    color={SERIES.engaged}
                  />
                ) : (
                  <p className="py-8 text-center text-sm text-gray-500">
                    Chưa có ai khai độ tuổi trong kỳ này.
                  </p>
                )}
              </section>
            </div>
          </section>
        </div>
      )}
    </DashboardShell>
  );
};

export default DashboardUsers;
