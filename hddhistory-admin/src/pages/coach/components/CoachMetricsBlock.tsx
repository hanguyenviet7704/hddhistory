import React, { useCallback, useEffect, useState } from "react";
import { ArrowPathIcon } from "@heroicons/react/24/outline";

import { formatNumber } from "../../../components/dashboard/dashboardTheme";
import { dashboardService } from "../../../services/dashboardService";
import {
  ICoachMetricItem,
  ICoachMetricsWeek,
} from "../../../types/interface/coachStats.interface";
import { SectionCard } from "./CoachStatsWidgets";

const GROUP_TITLES: Record<string, string> = {
  quality: "Coach nói có ổn không",
  funnel: "Có ai đi tới đâu không",
};

const GROUP_HINTS: Record<string, string> = {
  quality:
    "Bộ đếm canh chính model: nháp bị từ chối, câu hỏi bị cấm, lời lặp lại chữ người đọc. Event tracking bên app không thấy được những thứ này vì app chỉ thấy phần đã lọt qua.",
  funnel:
    "Bộ đếm canh đường đi: cam kết có được nhận không, điểm danh chia ra sao, card khoá học có ai mở không.",
};

const MetricRow: React.FC<{ item: ICoachMetricItem }> = ({ item }) => (
  <li className="rounded-lg border border-gray-100 bg-gray-50 px-3 py-2">
    <div className="flex items-baseline justify-between gap-3">
      <span className="truncate text-sm text-gray-800" title={item.label}>
        {item.label}
      </span>
      <span className="shrink-0 text-sm font-semibold tabular-nums text-gray-900">
        {formatNumber(item.count)}
      </span>
    </div>
    {item.refs.length > 0 && (
      <ul className="mt-1.5 flex flex-wrap gap-1.5">
        {item.refs.map((ref) => (
          <li
            key={ref.refId}
            className="rounded-full bg-white px-2 py-0.5 text-[11px] text-gray-600 ring-1 ring-gray-200"
            title={item.refLabel ?? undefined}
          >
            {ref.refId} · {formatNumber(ref.count)}
          </li>
        ))}
      </ul>
    )}
  </li>
);

/**
 * The Coach's own weekly counters.
 *
 * Its own block with its own picker, deliberately not folded into the page's
 * date range: the server writes these per ISO week and there is no day inside
 * one to slice. Showing them under a "01/09 – 07/09" header would put a number
 * next to a period it was never measured over.
 *
 * Fetched separately from the rest of the page for the same reason — a
 * different endpoint, a different grain, and a failure here must not blank out
 * the four blocks above it.
 */
const CoachMetricsBlock: React.FC = () => {
  const [data, setData] = useState<ICoachMetricsWeek | null>(null);
  const [week, setWeek] = useState<string | undefined>(undefined);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  const load = useCallback((isoWeek?: string) => {
    let cancelled = false;
    setLoading(true);
    setError(null);

    dashboardService
      .getCoachMetrics(isoWeek)
      .then((result) => {
        if (cancelled) return;
        setData(result);
        // The server picks the newest week that HAS data when none is asked
        // for; adopt its answer so the picker agrees with what is on screen.
        setWeek(result.isoWeek);
      })
      .catch((err: any) => {
        if (cancelled) return;
        setError(
          err?.response?.data?.message ||
            err?.message ||
            "Không tải được bộ đếm",
        );
      })
      .finally(() => {
        if (!cancelled) setLoading(false);
      });

    return () => {
      cancelled = true;
    };
  }, []);

  useEffect(() => load(), [load]);

  const groups: ("quality" | "funnel")[] = ["quality", "funnel"];

  return (
    <SectionCard
      index="⑤"
      title="Bộ đếm của server, theo tuần ISO"
      description="Đếm ở phía server nên không phụ thuộc bản app người dùng đang cài — có dữ liệu kể cả khi event tracking chưa lên bản prod. Không gắn với user nào: đây là tỉ lệ, không phải hồ sơ."
      action={
        <div className="flex items-center gap-2">
          {loading && (
            <ArrowPathIcon
              className="h-4 w-4 animate-spin text-gray-400"
              aria-label="Đang tải"
            />
          )}
          <select
            value={week ?? ""}
            onChange={(event) => {
              const next = event.target.value;
              setWeek(next);
              load(next);
            }}
            disabled={!data?.weeks.length}
            className="rounded-lg border border-gray-300 bg-white px-2.5 py-1.5 text-sm text-gray-800 disabled:bg-gray-50 disabled:text-gray-400"
            aria-label="Chọn tuần ISO"
          >
            {data?.weeks.length ? (
              data.weeks.map((option) => (
                <option key={option} value={option}>
                  Tuần {option}
                </option>
              ))
            ) : (
              <option value="">Chưa có tuần nào</option>
            )}
          </select>
        </div>
      }
    >
      {error ? (
        <p className="rounded-lg border border-rose-200 bg-rose-50 px-3 py-6 text-center text-sm text-rose-700">
          {error}
        </p>
      ) : data && !data.hasData ? (
        <p className="rounded-lg border border-gray-200 bg-gray-50 px-3 py-6 text-center text-sm text-gray-500">
          Tuần {data.isoWeek} chưa có bộ đếm nào. Các loại vẫn liệt kê bên dưới
          với số 0 để phân biệt "tuần này không xảy ra" với "chưa ai gắn bộ
          đếm".
        </p>
      ) : null}

      {data && (
        <div className="mt-3 grid grid-cols-1 gap-4 lg:grid-cols-2">
          {groups.map((group) => {
            const items = data.items.filter((item) => item.group === group);
            if (!items.length) return null;

            return (
              <div key={group}>
                <h3 className="text-xs font-semibold uppercase tracking-wide text-gray-500">
                  {GROUP_TITLES[group]}
                </h3>
                <p className="mt-0.5 text-xs text-gray-500">
                  {GROUP_HINTS[group]}
                </p>
                <ul className="mt-2 space-y-1.5">
                  {items.map((item) => (
                    <MetricRow key={item.kind} item={item} />
                  ))}
                </ul>
              </div>
            );
          })}
        </div>
      )}
    </SectionCard>
  );
};

export default CoachMetricsBlock;
