import React, { useCallback, useEffect, useState } from "react";

import { learningImportService } from "../../services/learningImportService";
import {
  ILearningImportConfig,
  ILearningImportStats,
} from "../../types/interface/learningImport.interface";
import { useNotification } from "../../utils/hooks/useNotification";
import { ERROR_LABELS, formatVnd } from "./learningImportLabels";

/**
 * What the feature has done, and the switch that stops it doing more.
 *
 * The two belong on one panel because they are read together: the reason to
 * reach for the switch is almost always something on the left — a failure rate
 * climbing, a cost line moving faster than expected.
 */
export default function ImportStatsPanel() {
  const { showError, showSuccess } = useNotification();

  const [stats, setStats] = useState<ILearningImportStats | null>(null);
  const [config, setConfig] = useState<ILearningImportConfig | null>(null);
  const [saving, setSaving] = useState(false);

  const load = useCallback(async () => {
    try {
      const [statsData, configData] = await Promise.all([
        learningImportService.getStats(),
        learningImportService.getConfig(),
      ]);
      setStats(statsData);
      setConfig(configData);
    } catch (error) {
      console.error("Failed to load import stats", error);
      showError("Failed to load import stats");
    }
  }, [showError]);

  useEffect(() => {
    load();
  }, [load]);

  /**
   * Optimistic, then reconciled with what the server actually stored.
   *
   * A switch that waits for a round trip before moving reads as broken, and this
   * one gets flipped in a hurry — usually while something is going wrong.
   */
  const toggleEnabled = async () => {
    if (!config || saving) return;
    const next = !config.enabled;

    setSaving(true);
    setConfig({ ...config, enabled: next });
    try {
      const saved = await learningImportService.updateConfig({ enabled: next });
      setConfig(saved);
      showSuccess(
        next
          ? "Lesson generation is back on"
          : "Lesson generation is off — users cannot start a new import",
      );
    } catch (error) {
      console.error("Failed to update import config", error);
      setConfig({ ...config, enabled: !next });
      showError("Could not change the switch");
    } finally {
      setSaving(false);
    }
  };

  return (
    <div className="mb-6 rounded-2xl border border-gray-200 bg-white p-5">
      <div className="mb-4 flex flex-wrap items-start justify-between gap-4">
        <div>
          <h2 className="text-base font-semibold text-gray-900">
            Feature health
          </h2>
          <p className="mt-0.5 text-sm text-gray-500">
            Counts and cost read straight off the jobs. Cost is the runner's own
            estimate, not a bill.
          </p>
        </div>

        <div className="flex items-center gap-3">
          <div className="text-right">
            <p className="text-sm font-medium text-gray-900">
              AI lesson generation
            </p>
            <p className="text-xs text-gray-500">
              {config?.enabled === false
                ? "Off — new imports are refused"
                : "On — users can create lessons"}
            </p>
          </div>
          <button
            type="button"
            role="switch"
            aria-checked={config?.enabled !== false}
            aria-label="Toggle AI lesson generation"
            disabled={!config || saving}
            onClick={toggleEnabled}
            className={`relative h-7 w-12 shrink-0 rounded-full transition-colors disabled:opacity-50 ${
              config?.enabled === false ? "bg-gray-300" : "bg-bronze-600"
            }`}
          >
            <span
              className={`absolute top-1 h-5 w-5 rounded-full bg-white shadow transition-transform ${
                config?.enabled === false ? "left-1" : "left-6"
              }`}
            />
          </button>
        </div>
      </div>

      {config?.enabled === false && (
        // Says what the switch does NOT do. Without this the obvious reading is
        // that everything import-related is dark, and someone re-enables it in a
        // panic over lessons that were never affected.
        <p className="mb-4 rounded-lg bg-amber-50 px-3 py-2 text-sm text-amber-800">
          Existing lessons stay readable and running jobs finish. Only starting a
          new import is blocked.
        </p>
      )}

      <div className="grid grid-cols-2 gap-3 md:grid-cols-4 xl:grid-cols-7">
        <StatCard label="Imports" value={stats?.totalJobs} />
        <StatCard label="Last 7 days" value={stats?.jobsLast7Days} />
        <StatCard label="Lessons made" value={stats?.totalLessons} />
        <StatCard
          label="Success"
          value={stats ? `${stats.successRate}%` : undefined}
          tone={
            stats && stats.successRate < 80 && stats.failedJobs > 0
              ? "warn"
              : "ok"
          }
        />
        <StatCard label="Failed" value={stats?.failedJobs} />
        <StatCard label="Users" value={stats?.uniqueUsers} />
        <StatCard
          label="Cost"
          value={stats ? formatVnd(stats.totalCostVnd) : undefined}
          hint={stats ? `${formatVnd(stats.averageCostVnd)} / lesson` : undefined}
        />
      </div>

      {(stats?.bySource.length || stats?.topErrors.length) && (
        <div className="mt-4 grid gap-4 md:grid-cols-2">
          {stats.bySource.length > 0 && (
            <Breakdown
              title="By source"
              rows={stats.bySource.map((row) => ({
                label: row.sourceType.toUpperCase(),
                count: row.count,
              }))}
            />
          )}
          {stats.topErrors.length > 0 && (
            <Breakdown
              title="Top failures"
              rows={stats.topErrors.map((row) => ({
                // The same sentence the app shows the user, so a support reply
                // does not have to translate a code by hand.
                label: ERROR_LABELS[row.code] ?? row.code,
                count: row.count,
              }))}
            />
          )}
        </div>
      )}
    </div>
  );
}

function StatCard({
  label,
  value,
  hint,
  tone = "ok",
}: {
  label: string;
  value?: number | string;
  hint?: string;
  tone?: "ok" | "warn";
}) {
  return (
    <div className="rounded-xl border border-gray-100 bg-gray-50 px-3 py-2.5">
      <p className="text-xs font-medium uppercase tracking-wide text-gray-500">
        {label}
      </p>
      <p
        className={`mt-1 text-lg font-semibold ${
          tone === "warn" ? "text-amber-600" : "text-gray-900"
        }`}
      >
        {value ?? "—"}
      </p>
      {hint && <p className="mt-0.5 text-xs text-gray-500">{hint}</p>}
    </div>
  );
}

function Breakdown({
  title,
  rows,
}: {
  title: string;
  rows: { label: string; count: number }[];
}) {
  return (
    <div className="rounded-xl border border-gray-100 p-3">
      <p className="mb-2 text-xs font-medium uppercase tracking-wide text-gray-500">
        {title}
      </p>
      <div className="flex flex-col gap-1.5">
        {rows.map((row) => (
          <div
            key={row.label}
            className="flex items-center justify-between gap-3 text-sm"
          >
            <span className="truncate text-gray-700">{row.label}</span>
            <span className="shrink-0 font-semibold text-gray-900">
              {row.count}
            </span>
          </div>
        ))}
      </div>
    </div>
  );
}
