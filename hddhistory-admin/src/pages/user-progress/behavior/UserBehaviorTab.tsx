import React, { useCallback, useEffect, useMemo, useState } from "react";
import { ArrowPathIcon } from "@heroicons/react/24/outline";
import {
  APP_ENV_OPTIONS,
  EVENT_PREFIX_PRESETS,
  RANGE_PRESETS,
} from "../../../config/analyticsFunnel";
import { analyticsService } from "../../../services/analyticsService";
import {
  IUserBehaviorSession,
  IUserBehaviorSummary,
} from "../../../types/interface/analytics.interface";
import BehaviorDistribution from "./BehaviorDistribution";
import BehaviorMetrics from "./BehaviorMetrics";
import OnboardingFunnel from "./OnboardingFunnel";
import SessionTimeline from "./SessionTimeline";
import { isoDaysAgo } from "./behaviorFormat";

const CUSTOM_RANGE = -1;

export default function UserBehaviorTab({ userId }: { userId: string }) {
  const [rangeDays, setRangeDays] = useState<number>(30);
  const [customFrom, setCustomFrom] = useState("");
  const [customTo, setCustomTo] = useState("");
  const [appEnv, setAppEnv] = useState("");
  const [namePrefix, setNamePrefix] = useState("");

  const [summary, setSummary] = useState<IUserBehaviorSummary | null>(null);
  const [summaryLoading, setSummaryLoading] = useState(false);
  const [summaryError, setSummaryError] = useState(false);

  const [sessions, setSessions] = useState<IUserBehaviorSession[]>([]);
  const [sessionsTruncated, setSessionsTruncated] = useState(false);
  const [sessionsLoading, setSessionsLoading] = useState(false);
  const [sessionsError, setSessionsError] = useState(false);

  const range = useMemo(() => {
    if (rangeDays === CUSTOM_RANGE) {
      return {
        from: customFrom ? new Date(customFrom).toISOString() : undefined,
        to: customTo
          ? new Date(`${customTo}T23:59:59.999`).toISOString()
          : undefined,
      };
    }
    return { from: isoDaysAgo(rangeDays), to: undefined };
  }, [customFrom, customTo, rangeDays]);

  const fetchSummary = useCallback(async () => {
    if (!userId) return;
    setSummaryLoading(true);
    setSummaryError(false);
    try {
      const res = await analyticsService.getUserSummary(userId, {
        from: range.from,
        to: range.to,
        appEnv: appEnv || undefined,
      });
      setSummary(res ?? null);
    } catch (error) {
      console.error("Failed to load behavior summary", error);
      setSummaryError(true);
    } finally {
      setSummaryLoading(false);
    }
  }, [appEnv, range.from, range.to, userId]);

  const fetchSessions = useCallback(async () => {
    if (!userId) return;
    setSessionsLoading(true);
    setSessionsError(false);
    try {
      const res = await analyticsService.getUserSessions(userId, {
        from: range.from,
        to: range.to,
        appEnv: appEnv || undefined,
      });
      setSessions(res?.items ?? []);
      setSessionsTruncated(!!res?.truncated);
    } catch (error) {
      console.error("Failed to load behavior sessions", error);
      setSessionsError(true);
    } finally {
      setSessionsLoading(false);
    }
  }, [appEnv, range.from, range.to, userId]);

  // Summary and sessions load independently: a failure in one must not blank the
  // other.
  useEffect(() => {
    fetchSummary();
  }, [fetchSummary]);

  useEffect(() => {
    fetchSessions();
  }, [fetchSessions]);

  const isEmpty =
    !summaryLoading &&
    !summaryError &&
    (summary?.totalEvents ?? 0) === 0 &&
    sessions.length === 0;

  return (
    <div className="space-y-3">
      <div className="flex flex-wrap items-end gap-2 rounded-lg border border-gray-200 bg-white p-3">
        <label className="flex flex-col gap-1">
          <span className="text-[11px] uppercase tracking-wide text-gray-400">
            Khoảng thời gian
          </span>
          <select
            value={rangeDays}
            onChange={(event) => setRangeDays(Number(event.target.value))}
            className="rounded-lg border border-gray-200 px-2 py-1.5 text-sm"
          >
            {RANGE_PRESETS.map((preset) => (
              <option key={preset.value} value={preset.value}>
                {preset.label}
              </option>
            ))}
            <option value={CUSTOM_RANGE}>Tuỳ chọn</option>
          </select>
        </label>

        {rangeDays === CUSTOM_RANGE ? (
          <>
            <label className="flex flex-col gap-1">
              <span className="text-[11px] uppercase tracking-wide text-gray-400">
                Từ ngày
              </span>
              <input
                type="date"
                value={customFrom}
                onChange={(event) => setCustomFrom(event.target.value)}
                className="rounded-lg border border-gray-200 px-2 py-1.5 text-sm"
              />
            </label>
            <label className="flex flex-col gap-1">
              <span className="text-[11px] uppercase tracking-wide text-gray-400">
                Đến ngày
              </span>
              <input
                type="date"
                value={customTo}
                onChange={(event) => setCustomTo(event.target.value)}
                className="rounded-lg border border-gray-200 px-2 py-1.5 text-sm"
              />
            </label>
          </>
        ) : null}

        <label className="flex flex-col gap-1">
          <span className="text-[11px] uppercase tracking-wide text-gray-400">
            Môi trường
          </span>
          <select
            value={appEnv}
            onChange={(event) => setAppEnv(event.target.value)}
            className="rounded-lg border border-gray-200 px-2 py-1.5 text-sm"
          >
            {APP_ENV_OPTIONS.map((option) => (
              <option key={option.value} value={option.value}>
                {option.label}
              </option>
            ))}
          </select>
        </label>

        <label className="flex flex-col gap-1">
          <span className="text-[11px] uppercase tracking-wide text-gray-400">
            Nhóm event (lọc trong session)
          </span>
          <select
            value={
              EVENT_PREFIX_PRESETS.some((preset) => preset.value === namePrefix)
                ? namePrefix
                : ""
            }
            onChange={(event) => setNamePrefix(event.target.value)}
            className="rounded-lg border border-gray-200 px-2 py-1.5 text-sm"
          >
            {EVENT_PREFIX_PRESETS.map((preset) => (
              <option key={preset.value || "all"} value={preset.value}>
                {preset.label}
              </option>
            ))}
          </select>
        </label>

        <label className="flex flex-col gap-1">
          <span className="text-[11px] uppercase tracking-wide text-gray-400">
            Tên event bắt đầu bằng
          </span>
          <input
            value={namePrefix}
            onChange={(event) => setNamePrefix(event.target.value)}
            placeholder="vd: keypoint_"
            className="w-44 rounded-lg border border-gray-200 px-2 py-1.5 text-sm font-mono"
          />
        </label>

        <button
          type="button"
          onClick={() => {
            fetchSummary();
            fetchSessions();
          }}
          disabled={summaryLoading || sessionsLoading}
          className="ml-auto inline-flex items-center gap-2 rounded-lg border border-gray-200 px-3 py-2 text-sm text-gray-700 shadow-sm hover:bg-gray-50 disabled:opacity-70"
        >
          <ArrowPathIcon
            className={`h-4 w-4 ${
              summaryLoading || sessionsLoading ? "animate-spin" : ""
            }`}
          />
          Làm mới
        </button>
      </div>

      {isEmpty ? (
        <div className="rounded-lg border border-gray-200 bg-white p-8 text-center">
          <p className="text-sm text-gray-600">
            Chưa có dữ liệu hành vi cho user này.
          </p>
          <p className="mt-1 text-xs text-gray-500">
            Event chỉ được lưu từ bản build có tracking backend trở đi — dữ liệu
            trước đó không lấy lại được. Kiểm tra lại khoảng thời gian và môi
            trường.
          </p>
        </div>
      ) : null}

      {summaryLoading && !summary ? (
        <div className="rounded-lg border border-gray-200 bg-white p-6 text-center text-sm text-gray-500">
          Đang tải chỉ số...
        </div>
      ) : summaryError ? (
        <div className="flex items-center justify-center gap-2 rounded-lg border border-rose-200 bg-white p-6 text-sm text-rose-600">
          Không tải được chỉ số hành vi.
          <button
            type="button"
            onClick={fetchSummary}
            className="text-brand-600 hover:text-brand-800"
          >
            Thử lại
          </button>
        </div>
      ) : summary ? (
        <>
          <BehaviorMetrics summary={summary} />
          <OnboardingFunnel summary={summary} />
          <BehaviorDistribution
            topScreens={summary.topScreens}
            topEvents={summary.topEvents}
          />
        </>
      ) : null}

      <div className="space-y-2">
        <h3 className="text-sm font-semibold text-gray-900">
          Timeline theo session
        </h3>
        {sessionsLoading && sessions.length === 0 ? (
          <div className="rounded-lg border border-gray-200 bg-white p-6 text-center text-sm text-gray-500">
            Đang tải session...
          </div>
        ) : sessionsError ? (
          <div className="flex items-center justify-center gap-2 rounded-lg border border-rose-200 bg-white p-6 text-sm text-rose-600">
            Không tải được session.
            <button
              type="button"
              onClick={fetchSessions}
              className="text-brand-600 hover:text-brand-800"
            >
              Thử lại
            </button>
          </div>
        ) : (
          <SessionTimeline
            userId={userId}
            sessions={sessions}
            truncated={sessionsTruncated}
            namePrefix={namePrefix}
          />
        )}
      </div>
    </div>
  );
}
