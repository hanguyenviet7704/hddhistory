import React from "react";

import {
  APP_ENVS,
  DashboardFilters,
  RANGE_PRESETS,
} from "./useDashboard";

interface Props {
  filters: DashboardFilters;
  activePreset: string | null;
  onPreset: (days: number) => void;
  onChange: (next: Partial<DashboardFilters>) => void;
  /** App versions seen in the current period, for the version picker. */
  appVersions?: string[];
}

const inputClass =
  "h-9 rounded-lg border border-gray-300 bg-white px-3 text-sm text-gray-700 " +
  "focus:border-blue-500 focus:outline-none focus:ring-1 focus:ring-blue-500";

/**
 * The one row of controls above every dashboard page.
 *
 * Presets first because they answer 90% of the question in one click; the exact
 * dates stay visible beside them so the period is never ambiguous.
 */
const DashboardFilterBar: React.FC<Props> = ({
  filters,
  activePreset,
  onPreset,
  onChange,
  appVersions = [],
}) => {
  return (
    <div className="flex flex-wrap items-end gap-3 rounded-xl border border-gray-200 bg-white p-3 shadow-sm">
      <div className="flex items-center gap-1">
        {RANGE_PRESETS.map((preset) => {
          const isActive = activePreset === preset.key;
          return (
            <button
              key={preset.key}
              type="button"
              onClick={() => onPreset(preset.days)}
              aria-pressed={isActive}
              className={`h-9 rounded-lg px-3 text-sm font-medium transition-colors ${
                isActive
                  ? "bg-blue-500 text-white"
                  : "border border-gray-300 bg-white text-gray-700 hover:bg-gray-50"
              }`}
            >
              {preset.label}
            </button>
          );
        })}
      </div>

      <label className="flex flex-col gap-1">
        <span className="text-[11px] font-medium uppercase tracking-wide text-gray-400">
          Từ ngày
        </span>
        <input
          type="date"
          value={filters.from}
          max={filters.to}
          onChange={(event) => onChange({ from: event.target.value })}
          className={inputClass}
        />
      </label>

      <label className="flex flex-col gap-1">
        <span className="text-[11px] font-medium uppercase tracking-wide text-gray-400">
          Đến ngày
        </span>
        <input
          type="date"
          value={filters.to}
          min={filters.from}
          onChange={(event) => onChange({ to: event.target.value })}
          className={inputClass}
        />
      </label>

      <label className="flex flex-col gap-1">
        <span className="text-[11px] font-medium uppercase tracking-wide text-gray-400">
          Môi trường
        </span>
        <select
          value={filters.appEnv}
          onChange={(event) => onChange({ appEnv: event.target.value })}
          className={inputClass}
        >
          {APP_ENVS.map((env) => (
            <option key={env} value={env}>
              {env}
            </option>
          ))}
        </select>
      </label>

      <label className="flex flex-col gap-1">
        <span className="text-[11px] font-medium uppercase tracking-wide text-gray-400">
          Nền tảng
        </span>
        <select
          value={filters.platform}
          onChange={(event) => onChange({ platform: event.target.value })}
          className={inputClass}
        >
          <option value="">Tất cả</option>
          <option value="ios">iOS</option>
          <option value="android">Android</option>
        </select>
      </label>

      {appVersions.length > 0 && (
        <label className="flex flex-col gap-1">
          <span className="text-[11px] font-medium uppercase tracking-wide text-gray-400">
            Bản app
          </span>
          <select
            value={filters.appVersion}
            onChange={(event) => onChange({ appVersion: event.target.value })}
            className={inputClass}
          >
            <option value="">Tất cả</option>
            {appVersions.map((version) => (
              <option key={version} value={version}>
                {version}
              </option>
            ))}
          </select>
        </label>
      )}
    </div>
  );
};

export default DashboardFilterBar;
