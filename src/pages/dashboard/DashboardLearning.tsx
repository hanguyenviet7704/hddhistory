import React, { useState } from "react";
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
  formatPercent,
} from "../../components/dashboard/dashboardTheme";
import {
  useDashboardData,
  useDashboardFilters,
} from "../../components/dashboard/useDashboard";
import { dashboardService } from "../../services/dashboardService";
import { ILearningMilestone } from "../../types/interface/dashboard.interface";

const PLATFORM_LABELS: Record<string, string> = {
  ios: "iOS",
  android: "Android",
};

/**
 * One rung of the learning funnel.
 *
 * The bar is the share still present; the platform line under it is what turns
 * "we lost 122 people" into "we lost them on Android", which is the only form
 * of the number anyone can act on.
 */
const FunnelStep: React.FC<{ step: ILearningMilestone }> = ({ step }) => (
  <li className="relative overflow-hidden rounded-lg border border-gray-100 bg-gray-50">
    <div
      className="absolute inset-y-0 left-0 opacity-20"
      style={{
        width: `${(step.passRate ?? 0) * 100}%`,
        backgroundColor: SERIES.active,
      }}
      aria-hidden
    />
    <div className="relative flex items-center justify-between gap-3 px-3 py-2.5">
      <div className="min-w-0">
        <p className="truncate text-sm font-medium text-gray-800">
          {step.label}
        </p>
        {step.byPlatform.length > 0 && (
          <p className="mt-0.5 text-xs text-gray-500">
            {step.byPlatform
              .map(
                (row) =>
                  `${PLATFORM_LABELS[row.name] ?? row.name} ${formatNumber(
                    row.value
                  )}`
              )
              .join(" · ")}
          </p>
        )}
      </div>
      <div className="shrink-0 text-right">
        <p className="text-lg font-semibold text-gray-900">
          {formatNumber(step.users)}
        </p>
        <p className="text-xs text-gray-500">{formatPercent(step.passRate)}</p>
      </div>
    </div>
  </li>
);

const DashboardLearning: React.FC = () => {
  const { filters, setFilters, applyPreset, activePreset, query } =
    useDashboardFilters();
  const { data, loading, error, reload } = useDashboardData(
    dashboardService.getLearning,
    query
  );
  const { search } = useLocation();
  const [ageTab, setAgeTab] = useState<string | null>(null);

  const activeAge =
    data?.byAge.find((group) => group.age === ageTab) ?? data?.byAge[0] ?? null;

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
          <section className="space-y-3">
            <h2 className="text-[11px] font-semibold uppercase tracking-wider text-gray-400">
              Hành vi học tập &amp; gắn kết
            </h2>
            <div className="grid grid-cols-1 gap-4 lg:grid-cols-3">
              <section className="rounded-xl border border-gray-200 bg-white p-4 shadow-sm lg:col-span-2">
                <h3 className="text-sm font-semibold text-gray-900">
                  Phễu học tập
                </h3>
                <p className="mb-3 mt-0.5 text-xs text-gray-500">
                  Số người khác nhau đi qua từng bước. Phần trăm so với bước đầu
                  tiên.
                </p>
                <ol className="space-y-2">
                  {data.milestones.map((milestone) => (
                    <FunnelStep key={milestone.key} step={milestone} />
                  ))}
                </ol>
              </section>

              <div className="space-y-4">
                <StatCard
                  label="Lượt xem màn hình"
                  value={formatNumber(data.engagement.screenViews)}
                  hint="Tổng lượt mở màn, không phải số người"
                  delta={
                    <DeltaBadge
                      current={data.engagement.screenViews}
                      previous={data.engagement.previousScreenViews}
                    />
                  }
                />
                <StatCard
                  label="Hoàn thành Keypoint"
                  value={formatNumber(data.engagement.keypointCompletions)}
                  hint={`Bởi ${formatNumber(
                    data.engagement.keypointCompletionUsers
                  )} người dùng`}
                />
              </div>
            </div>
          </section>

          <section className="space-y-3">
            <h2 className="text-[11px] font-semibold uppercase tracking-wider text-gray-400">
              Khoá học người dùng quan tâm
            </h2>

            {data.heroCourse && (
              <div className="rounded-xl border border-gray-200 bg-white p-5 shadow-sm">
                <p className="text-xl font-semibold text-gray-900">
                  {data.heroCourse.name}
                </p>
                <p className="mt-1 text-sm text-gray-600">
                  Là khoá được tương tác nhiều nhất trong kỳ (
                  {formatNumber(data.heroCourse.events)} lượt sự kiện, từ{" "}
                  {formatNumber(data.heroCourse.users)} người).
                </p>
              </div>
            )}

            <section className="rounded-xl border border-gray-200 bg-white p-4 shadow-sm">
              <h3 className="text-sm font-semibold text-gray-900">
                Nhóm kỹ năng được quan tâm
              </h3>
              <p className="mb-3 mt-0.5 text-xs text-gray-500">
                Theo trường <code>skill_name</code> gắn kèm mỗi sự kiện học.
              </p>
              <TopList rows={data.topSkills} measureLabel="Người học" />
            </section>

            <div className="grid grid-cols-1 gap-4 lg:grid-cols-2">
              {data.courseRankings.map((ranking) => (
                <section
                  key={ranking.key}
                  className="rounded-xl border border-gray-200 bg-white p-4 shadow-sm"
                >
                  <h3 className="text-sm font-semibold text-gray-900">
                    {ranking.label}
                  </h3>
                  <p className="mb-3 mt-0.5 text-xs text-gray-500">
                    {ranking.hint} ({ranking.event}) · số người
                  </p>
                  <TopList rows={ranking.rows} measureLabel="Người dùng" />
                </section>
              ))}
            </div>
          </section>

          <section className="rounded-xl border border-gray-200 bg-white p-4 shadow-sm">
            <h2 className="text-sm font-semibold text-gray-900">
              Chủ đề quan tâm &amp; hoàn thành theo độ tuổi
            </h2>
            <p className="mt-0.5 text-xs text-gray-500">
              Ghép độ tuổi khai lúc onboarding với khoá học từng người đọc và
              hoàn thành. Chọn nhóm tuổi để xem.
            </p>

            {data.byAge.length === 0 ? (
              <p className="py-8 text-center text-sm text-gray-500">
                Chưa có ai vừa khai độ tuổi vừa có hoạt động học trong kỳ này.
              </p>
            ) : (
              <>
                <div
                  className="mt-3 flex flex-wrap items-center gap-1"
                  role="group"
                  aria-label="Nhóm tuổi"
                >
                  {data.byAge.map((group) => {
                    const isActive = activeAge?.age === group.age;
                    return (
                      <button
                        key={group.age}
                        type="button"
                        onClick={() => setAgeTab(group.age)}
                        aria-pressed={isActive}
                        className={`h-8 rounded-lg px-3 text-xs font-medium transition-colors ${
                          isActive
                            ? "bg-blue-500 text-white"
                            : "border border-gray-300 bg-white text-gray-700 hover:bg-gray-50"
                        }`}
                      >
                        {group.age}
                        <span
                          className={`ml-1.5 ${
                            isActive ? "text-blue-100" : "text-gray-400"
                          }`}
                        >
                          {formatNumber(group.users)}
                        </span>
                      </button>
                    );
                  })}
                </div>

                {activeAge && (
                  <div className="mt-4 grid grid-cols-1 gap-4 lg:grid-cols-2">
                    <div>
                      <h3 className="mb-2 text-sm font-medium text-gray-800">
                        Quan tâm nhất (vào đọc bài)
                      </h3>
                      <TopList
                        rows={activeAge.interested}
                        measureLabel="Người đọc"
                      />
                    </div>
                    <div>
                      <h3 className="mb-2 text-sm font-medium text-gray-800">
                        Hoàn thành nhiều nhất
                      </h3>
                      <TopList
                        rows={activeAge.completed}
                        measureLabel="Người hoàn thành"
                        color={SERIES.new}
                      />
                    </div>
                  </div>
                )}
              </>
            )}
          </section>

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

          <div className="rounded-xl border border-gray-200 bg-white p-4 shadow-sm">
            <p className="text-xs text-gray-500">
              Bảng khoá dùng <code>course_name</code> gắn kèm sự kiện, nên tên
              hiển thị đúng như app gửi lên.{" "}
              <Link
                to={`/statistics${search}`}
                className="font-medium text-blue-600 hover:underline"
              >
                Xem tiến trình theo khoá →
              </Link>
            </p>
          </div>
        </div>
      )}
    </DashboardShell>
  );
};

export default DashboardLearning;
