import React from "react";
import {
  ArrowPathIcon,
  ExclamationTriangleIcon,
  InboxIcon,
} from "@heroicons/react/24/outline";

import { IDashboardRange } from "../../types/interface/dashboard.interface";
import DashboardFilterBar from "./DashboardFilterBar";
import { formatDate } from "./dashboardTheme";
import { DashboardFilters } from "./useDashboard";

interface Props {
  title: string;
  subtitle: string;
  filters: DashboardFilters;
  activePreset: string | null;
  onPreset: (days: number) => void;
  onChange: (next: Partial<DashboardFilters>) => void;
  appVersions?: string[];
  range?: IDashboardRange | null;
  compareRange?: IDashboardRange | null;
  loading: boolean;
  error: string | null;
  hasData: boolean;
  isEmpty?: boolean;
  onReload: () => void;
  children: React.ReactNode;
}

const Skeleton: React.FC = () => (
  <div className="space-y-4" aria-busy="true" aria-label="Đang tải dữ liệu">
    <div className="grid grid-cols-1 gap-4 sm:grid-cols-2 lg:grid-cols-4">
      {[0, 1, 2, 3].map((key) => (
        <div
          key={key}
          className="h-24 animate-pulse rounded-xl border border-gray-200 bg-white"
        />
      ))}
    </div>
    <div className="h-72 animate-pulse rounded-xl border border-gray-200 bg-white" />
  </div>
);

/**
 * Page chrome shared by all five dashboard screens: heading, the period it is
 * measuring, the filter row, and the four states every page must handle.
 *
 * Loading only replaces the content on a cold start — once there is data on
 * screen, a filter change dims it and shows a spinner instead of throwing the
 * reader back to a skeleton.
 */
const DashboardShell: React.FC<Props> = ({
  title,
  subtitle,
  filters,
  activePreset,
  onPreset,
  onChange,
  appVersions,
  range,
  compareRange,
  loading,
  error,
  hasData,
  isEmpty,
  onReload,
  children,
}) => {
  const showSkeleton = loading && !hasData;

  return (
    <div className="min-h-screen bg-gray-50 p-6">
      <div className="mx-auto max-w-7xl space-y-4">
        <header className="flex flex-wrap items-start justify-between gap-3">
          <div>
            <h1 className="text-xl font-semibold text-gray-900">{title}</h1>
            <p className="mt-0.5 text-sm text-gray-500">{subtitle}</p>
          </div>
          <div className="text-right">
            {range && (
              <p className="text-sm font-medium text-gray-700">
                {formatDate(range.from)} – {formatDate(range.to)} · {range.days}{" "}
                ngày
              </p>
            )}
            {compareRange && (
              <p className="text-xs text-gray-500">
                So với {formatDate(compareRange.from)} –{" "}
                {formatDate(compareRange.to)}
              </p>
            )}
          </div>
        </header>

        <DashboardFilterBar
          filters={filters}
          activePreset={activePreset}
          onPreset={onPreset}
          onChange={onChange}
          appVersions={appVersions}
        />

        {error ? (
          <div className="flex flex-col items-center gap-3 rounded-xl border border-rose-200 bg-rose-50 p-10 text-center">
            <ExclamationTriangleIcon className="h-8 w-8 text-rose-500" />
            <div>
              <p className="font-medium text-rose-800">Không tải được dữ liệu</p>
              <p className="mt-1 text-sm text-rose-700">{error}</p>
            </div>
            <button
              type="button"
              onClick={onReload}
              className="inline-flex items-center gap-2 rounded-lg bg-rose-600 px-4 py-2 text-sm font-medium text-white hover:bg-rose-700"
            >
              <ArrowPathIcon className="h-4 w-4" />
              Thử lại
            </button>
          </div>
        ) : showSkeleton ? (
          <Skeleton />
        ) : isEmpty ? (
          <div className="flex flex-col items-center gap-3 rounded-xl border border-gray-200 bg-white p-12 text-center">
            <InboxIcon className="h-8 w-8 text-gray-400" />
            <div>
              <p className="font-medium text-gray-800">
                Kỳ này chưa có dữ liệu
              </p>
              <p className="mt-1 text-sm text-gray-500">
                Không có sự kiện nào ở môi trường{" "}
                <span className="font-medium">{filters.appEnv}</span> trong
                khoảng đã chọn. Thử nới khoảng ngày hoặc đổi môi trường.
              </p>
            </div>
          </div>
        ) : (
          <div className={loading ? "opacity-60 transition-opacity" : undefined}>
            {loading && (
              <p className="mb-2 flex items-center gap-2 text-xs text-gray-500">
                <ArrowPathIcon className="h-3.5 w-3.5 animate-spin" />
                Đang cập nhật…
              </p>
            )}
            {children}
          </div>
        )}
      </div>
    </div>
  );
};

export default DashboardShell;
