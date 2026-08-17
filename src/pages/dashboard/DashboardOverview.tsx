import React from "react";
import { Link, useLocation } from "react-router-dom";
import {
  ArrowRightIcon,
  ArrowTrendingUpIcon,
  BookOpenIcon,
  ClockIcon,
  DevicePhoneMobileIcon,
  RocketLaunchIcon,
  UserGroupIcon,
} from "@heroicons/react/24/outline";

import DashboardShell from "../../components/dashboard/DashboardShell";
import StatCard, { DeltaBadge } from "../../components/dashboard/StatCard";
import VersionDepthChart from "../../components/dashboard/VersionDepthChart";
import { labelForStep } from "../../components/dashboard/onboardingStepLabels";
import {
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
import { IRetentionPoint } from "../../types/interface/dashboard.interface";

const findOffset = (points: IRetentionPoint[], offset: number) =>
  points.find((point) => point.offset === offset) ?? null;

/** Card heading that links through to the page which explains the number. */
const SectionCard: React.FC<{
  title: string;
  icon: React.ReactNode;
  to: string;
  children: React.ReactNode;
  reading?: React.ReactNode;
}> = ({ title, icon, to, children, reading }) => (
  <section className="rounded-xl border border-gray-200 bg-white p-4 shadow-sm">
    <div className="flex items-center justify-between gap-2">
      <h2 className="flex items-center gap-2 text-sm font-semibold text-gray-900">
        <span className="text-gray-400">{icon}</span>
        {title}
      </h2>
      <Link
        to={to}
        className="flex h-7 w-7 items-center justify-center rounded-full bg-gray-100 text-gray-500 transition-colors hover:bg-blue-50 hover:text-blue-600"
        aria-label={`Xem chi tiết ${title}`}
      >
        <ArrowRightIcon className="h-4 w-4" />
      </Link>
    </div>
    <div className="mt-3">{children}</div>
    {reading && (
      <p className="mt-3 border-t border-gray-100 pt-3 text-xs leading-relaxed text-gray-600">
        {reading}
      </p>
    )}
  </section>
);

const Figure: React.FC<{
  value: string;
  label: string;
  delta?: React.ReactNode;
}> = ({ value, label, delta }) => (
  <div>
    <div className="flex items-baseline gap-2">
      <span className="text-2xl font-semibold text-gray-900">{value}</span>
      {delta}
    </div>
    <p className="mt-0.5 text-xs text-gray-500">{label}</p>
  </div>
);

const DashboardOverview: React.FC = () => {
  const { filters, setFilters, applyPreset, activePreset, query } =
    useDashboardFilters();
  const { data, loading, error, reload } = useDashboardData(
    dashboardService.getOverview,
    query
  );
  const { search } = useLocation();

  const d1 = data ? findOffset(data.retention, 1) : null;
  const d7 = data ? findOffset(data.retention, 7) : null;
  const peak = data?.peakHours ?? [];

  return (
    <DashboardShell
      title="Báo cáo tuần"
      subtitle="Sức khỏe sản phẩm — mỗi ô dẫn tới trang giải thích con số đó."
      filters={filters}
      activePreset={activePreset}
      onPreset={applyPreset}
      onChange={setFilters}
      range={data?.range}
      compareRange={data?.compareRange}
      loading={loading}
      error={error}
      hasData={Boolean(data)}
      isEmpty={Boolean(data && data.users.active === 0)}
      onReload={reload}
    >
      {data && (
        <div className="space-y-4">
        <div className="grid grid-cols-1 gap-4 lg:grid-cols-2">
          <SectionCard
            title="Người dùng"
            icon={<UserGroupIcon className="h-4 w-4" />}
            to={`/dashboard/users${search}`}
            reading={
              <>
                <strong>{formatNumber(data.users.active)}</strong> người hoạt
                động trong kỳ, trong đó{" "}
                <strong>{formatNumber(data.users.new)}</strong> là người mới và{" "}
                <strong>{formatNumber(data.users.returning)}</strong> quay lại.
              </>
            }
          >
            <div className="grid grid-cols-3 gap-3">
              <Figure
                value={formatNumber(data.users.active)}
                label="Hoạt động"
                delta={
                  <DeltaBadge
                    current={data.users.active}
                    previous={data.users.previous?.active}
                  />
                }
              />
              <Figure
                value={formatNumber(data.users.new)}
                label="Người mới"
                delta={
                  <DeltaBadge
                    current={data.users.new}
                    previous={data.users.previous?.new}
                  />
                }
              />
              <Figure
                value={formatNumber(data.users.returning)}
                label="Quay lại"
                delta={
                  <DeltaBadge
                    current={data.users.returning}
                    previous={data.users.previous?.returning}
                  />
                }
              />
            </div>
          </SectionCard>

          <SectionCard
            title="Giữ chân (Retention)"
            icon={<ArrowTrendingUpIcon className="h-4 w-4" />}
            to={`/dashboard/users${search}`}
            reading={
              d7?.rate === null ? (
                <>
                  Chưa nhóm người dùng nào đủ 7 ngày tuổi trong kỳ này — D7 sẽ
                  có số khi cohort đủ tuổi, không phải 0%.
                </>
              ) : (
                <>
                  Tính theo cohort ngày đăng ký: trong{" "}
                  <strong>{formatNumber(d1?.cohortUsers ?? 0)}</strong> người
                  đăng ký đủ tuổi đo, {formatPercent(d1?.rate)} quay lại vào
                  ngày kế tiếp.
                </>
              )
            }
          >
            <div className="grid grid-cols-2 gap-3">
              <Figure value={formatPercent(d1?.rate)} label="Quay lại sau ngày 1" />
              <Figure value={formatPercent(d7?.rate)} label="Quay lại sau 7 ngày" />
            </div>
          </SectionCard>

          <SectionCard
            title="Phiên & Tương tác"
            icon={<DevicePhoneMobileIcon className="h-4 w-4" />}
            to={`/dashboard/sessions${search}`}
            reading={
              peak.length > 0 ? (
                <>
                  Khung giờ vàng:{" "}
                  <strong>
                    {peak.map((point) => formatHour(point.hour)).join(", ")}
                  </strong>{" "}
                  — thời điểm tốt để đẩy thông báo nhắc học.
                </>
              ) : undefined
            }
          >
            <div className="grid grid-cols-2 gap-3">
              <Figure
                value={formatNumber(data.sessions.total)}
                label="Phiên truy cập"
                delta={
                  <DeltaBadge
                    current={data.sessions.total}
                    previous={data.sessions.previousTotal}
                  />
                }
              />
              <Figure
                value={formatPercent(data.sessions.engagementRate)}
                label="Phiên có tương tác"
              />
            </div>
          </SectionCard>

          <SectionCard
            title="Onboarding"
            icon={<RocketLaunchIcon className="h-4 w-4" />}
            to={`/dashboard/onboarding${search}`}
            reading={
              data.onboarding.biggestDrop ? (
                <>
                  Rớt mạnh nhất ở{" "}
                  <strong>
                    {labelForStep(data.onboarding.biggestDrop.event)}
                  </strong>{" "}
                  — mất{" "}
                  {formatNumber(data.onboarding.biggestDrop.dropUsers)} người (
                  {formatPercent(data.onboarding.biggestDrop.dropRate)}).
                </>
              ) : undefined
            }
          >
            <div className="grid grid-cols-2 gap-3">
              <Figure
                value={formatNumber(data.onboarding.started)}
                label="Bắt đầu onboarding"
                delta={undefined}
              />
              <Figure
                value={formatPercent(data.onboarding.completionRate)}
                label={`Hoàn tất (${formatNumber(data.onboarding.completed)})`}
              />
            </div>
          </SectionCard>

          <SectionCard
            title="Hành vi học"
            icon={<BookOpenIcon className="h-4 w-4" />}
            to={`/dashboard/learning${search}`}
            reading={
              data.learning.topCourse ? (
                <>
                  Khoá được học nhiều nhất:{" "}
                  <strong>{data.learning.topCourse.name}</strong> (
                  {formatNumber(data.learning.topCourse.users)} người)
                  {data.learning.topSkill && (
                    <>
                      ; nhóm kỹ năng dẫn đầu là{" "}
                      <strong>{data.learning.topSkill.name}</strong>
                    </>
                  )}
                  .
                </>
              ) : undefined
            }
          >
            <div className="grid grid-cols-2 gap-3">
              <Figure
                value={formatNumber(data.learning.roadmapOpened)}
                label="Mở lộ trình"
              />
              <Figure
                value={formatNumber(data.learning.lessonCompleted)}
                label="Hoàn thành bài"
              />
            </div>
          </SectionCard>

          <SectionCard
            title="Khung giờ học"
            icon={<ClockIcon className="h-4 w-4" />}
            to={`/dashboard/sessions${search}`}
          >
            {peak.length ? (
              <div className="grid grid-cols-3 gap-3">
                {peak.map((point, index) => (
                  <StatCard
                    key={point.hour}
                    label={index === 0 ? "Cao nhất" : `Kế tiếp`}
                    value={formatHour(point.hour)}
                    hint={`${formatNumber(point.events)} sự kiện`}
                  />
                ))}
              </div>
            ) : (
              <p className="py-6 text-center text-sm text-gray-500">
                Chưa có dữ liệu giờ học trong kỳ
              </p>
            )}
          </SectionCard>
        </div>

        {data.versionDepth.versions.length > 0 && (
          <section className="space-y-3">
            <h2 className="text-[11px] font-semibold uppercase tracking-wider text-gray-400">
              Gắn kết (Engagement)
            </h2>
            <div className="rounded-xl border border-gray-200 bg-white p-4 shadow-sm">
              <h3 className="text-sm font-semibold text-gray-900">
                Độ sâu mỗi phiên học
              </h3>
              <p className="mt-0.5 text-xs text-gray-500">
                Bốn thước đo mức độ học của người dùng, so giữa các bản app
                {data.versionDepth.deltas.from && data.versionDepth.deltas.to
                  ? ` · mũi tên là thay đổi từ ${data.versionDepth.deltas.from} tới ${data.versionDepth.deltas.to}`
                  : ""}
                .
              </p>
              <div className="mt-4 grid grid-cols-1 gap-4 sm:grid-cols-2 lg:grid-cols-4">
                <VersionDepthChart
                  title="Thời lượng phiên"
                  points={data.versionDepth.versions.map((row) => ({
                    appVersion: row.appVersion,
                    value: row.sessionMedianMs,
                  }))}
                  format={(value) => formatDuration(value)}
                  delta={data.versionDepth.deltas.sessionDurationPct}
                />
                <VersionDepthChart
                  title="Số bài hoàn thành / phiên"
                  points={data.versionDepth.versions.map((row) => ({
                    appVersion: row.appVersion,
                    value: row.lessonsPerSession,
                  }))}
                  format={(value) =>
                    value === null ? "—" : value.toFixed(2).replace(".", ",")
                  }
                  delta={data.versionDepth.deltas.lessonsPerSessionPct}
                />
                <VersionDepthChart
                  title="Tỷ lệ người hoàn thành bài"
                  points={data.versionDepth.versions.map((row) => ({
                    appVersion: row.appVersion,
                    value: row.completionRate,
                  }))}
                  format={(value) => formatPercent(value)}
                  delta={data.versionDepth.deltas.completionRatePoints}
                  deltaKind="points"
                />
                <VersionDepthChart
                  title="Số phiên / người / ngày"
                  points={data.versionDepth.versions.map((row) => ({
                    appVersion: row.appVersion,
                    value: row.sessionsPerUserPerDay,
                  }))}
                  format={(value) =>
                    value === null ? "—" : value.toFixed(2).replace(".", ",")
                  }
                  delta={data.versionDepth.deltas.sessionsPerUserPerDayPct}
                  // Fewer, longer visits is the goal here, so a fall alongside
                  // rising duration is a good outcome, not a regression.
                  invert
                />
              </div>
              <p className="mt-4 border-t border-gray-100 pt-3 text-xs leading-relaxed text-gray-600">
                Đọc bốn ô cùng lúc: thời lượng và số bài mỗi phiên tăng trong
                khi số phiên mỗi người mỗi ngày giảm nghĩa là người dùng{" "}
                <strong>vào ít lần hơn nhưng học sâu hơn</strong> — không phải
                sa sút.
              </p>
            </div>
          </section>
        )}
        </div>
      )}
    </DashboardShell>
  );
};

export default DashboardOverview;
