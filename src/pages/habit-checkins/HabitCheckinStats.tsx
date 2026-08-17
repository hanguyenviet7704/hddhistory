import { useCallback, useEffect, useState } from "react";
import { useSelector } from "react-redux";
import { Link } from "react-router-dom";

import { RootState } from "../../store";
import { userHabitService } from "../../services/userHabitService";
import {
  IHabitCheckinStatistics,
  IHabitDailyPoint,
} from "../../types/interface/userHabit.interface";
import { getTranslationValue } from "../../utils/translation";
import { useNotification } from "../../utils/hooks/useNotification";
import {
  MethodPill,
  formatDateOnly,
  renderMood,
} from "./habitCheckinLabels";

type DatePreset = "30" | "60" | "all" | "custom";

const toInputDate = (date: Date) => {
  const offset = date.getTimezoneOffset();
  return new Date(date.getTime() - offset * 60_000).toISOString().slice(0, 10);
};

const presetRange = (days: number) => {
  const end = new Date();
  const start = new Date();
  start.setDate(start.getDate() - (days - 1));
  return { startDate: toInputDate(start), endDate: toInputDate(end) };
};

const formatNumber = (value?: number | null) =>
  value === null || value === undefined ? "-" : value.toLocaleString("vi-VN");

const MOOD_BAR_COLORS: Record<number, string> = {
  1: "bg-red-500",
  2: "bg-amber-500",
  3: "bg-emerald-600",
};

/**
 * Aggregate view of habit usage, beside the per-user table.
 *
 * Everything here is an event count: `habit_checkins` carries one row per habit
 * per day, so "120 check-in" is 120 real days of practice. (The lesson-feedback
 * statistics cannot say that — there, each user keeps only their latest
 * submission.)
 */
export default function HabitCheckinStats() {
  const lang = useSelector((state: RootState) => state.lang.code);
  const { showError } = useNotification();

  const [preset, setPreset] = useState<DatePreset>("30");
  const [range, setRange] = useState(() => presetRange(30));
  const [data, setData] = useState<IHabitCheckinStatistics | null>(null);
  const [loading, setLoading] = useState(true);

  const query = useCallback(
    () =>
      preset === "all"
        ? {}
        : { startDate: range.startDate, endDate: range.endDate },
    [preset, range]
  );

  useEffect(() => {
    let cancelled = false;
    setLoading(true);
    userHabitService
      .getCheckinStatistics(query())
      .then((res) => {
        if (!cancelled) setData(res);
      })
      .catch((error: any) => {
        if (cancelled) return;
        showError(
          error?.response?.data?.message || "Không tải được thống kê habit"
        );
      })
      .finally(() => {
        if (!cancelled) setLoading(false);
      });
    return () => {
      cancelled = true;
    };
    // showError is re-created each render by the hook; depending on it loops.
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [query]);

  const onPresetChange = (value: DatePreset) => {
    setPreset(value);
    if (value === "30" || value === "60") setRange(presetRange(Number(value)));
  };

  const m = data?.metrics;
  // Zero-filled timeline. The API only returns days that HAVE check-ins, so
  // drawing its rows side by side silently deletes the quiet days from the axis
  // and turns "26 of 30 days" into a solid streak. Filling the gaps is what
  // makes the shape of the chart mean anything.
  const series = buildSeries(data, preset === "all" ? undefined : range);
  const maxDaily = Math.max(1, ...series.map((d) => d.checkins));
  const maxMethod = Math.max(
    1,
    ...(data?.methodDistribution || []).map((r) => r.count)
  );
  const maxStreak = Math.max(
    1,
    ...(data?.streakBuckets || []).map((r) => r.count)
  );

  return (
    <div className="space-y-6">
      <div className="flex flex-wrap items-center gap-3 rounded-xl border border-slate-200 bg-white px-4 py-2 shadow-sm">
        <span className="text-sm text-slate-500">Khoảng ngày:</span>
        <select
          value={preset}
          onChange={(event) => onPresetChange(event.target.value as DatePreset)}
          className="rounded-lg border-0 bg-transparent text-sm font-semibold text-slate-900 outline-none"
        >
          <option value="30">30 ngày gần nhất</option>
          <option value="60">60 ngày gần nhất</option>
          <option value="all">Tất cả</option>
          <option value="custom">Tuỳ chọn</option>
        </select>
        {preset === "custom" ? (
          <>
            <input
              type="date"
              value={range.startDate}
              onChange={(event) =>
                setRange((prev) => ({ ...prev, startDate: event.target.value }))
              }
              className="rounded-lg border border-slate-200 px-2 py-1 text-sm"
            />
            <span className="text-slate-400">→</span>
            <input
              type="date"
              value={range.endDate}
              onChange={(event) =>
                setRange((prev) => ({ ...prev, endDate: event.target.value }))
              }
              className="rounded-lg border border-slate-200 px-2 py-1 text-sm"
            />
          </>
        ) : null}
      </div>

      {loading && !data ? (
        <div className="rounded-2xl border border-slate-200 bg-white p-8 text-center text-sm text-slate-500">
          Đang tải…
        </div>
      ) : null}

      {m ? (
        <>
          <div className="grid grid-cols-1 gap-4 md:grid-cols-2 xl:grid-cols-4">
            <StatCard
              label="Check-in"
              value={m.checkins.value}
              delta={m.checkins.delta}
            />
            <StatCard
              label="Người check-in"
              value={m.users.value}
              delta={m.users.delta}
            />
            <StatCard
              label="Tỉ lệ hoàn thành"
              value={m.doneRate.value}
              suffix="%"
              hint="Số dòng done / tổng check-in"
            />
            <StatCard
              label="Habit đang active"
              value={m.activeHabits.value}
              hint={`${formatNumber(m.adoptedByUsers.value)} người đã nhận habit · ${formatNumber(
                m.draftHabits.value
              )} draft · ${formatNumber(m.archivedHabits.value)} archived`}
            />
          </div>

          <div className="grid grid-cols-1 gap-4 md:grid-cols-3">
            <StatCard
              label="Có nhật ký"
              value={m.withNote.value}
              hint="Check-in kèm nội dung viết"
            />
            <StatCard
              label="Mood trung bình"
              value={m.averageMood.value}
              denominator="3"
              hint="Chỉ tính check-in kiểu Journal"
            />
            <StatCard
              label="Quiz"
              value={m.quizCount.value}
              hint={`Điểm trung bình ${
                m.averageQuizScore.value ?? "-"
              } câu đúng`}
            />
          </div>

          <Section
            title="Check-in theo ngày"
            trailing={`${formatNumber(data?.daily.length)} / ${formatNumber(
              series.length
            )} ngày có hoạt động · cao nhất ${formatNumber(maxDaily)} check-in/ngày`}
          >
            {series.length === 0 ? (
              <Empty />
            ) : (
              // Plain divs, not a chart library: one bar per day over a window of
              // weeks. Bars flex so a month fills the card instead of hugging the
              // left edge, and a zero day renders as a visible gap.
              <div>
                <div className="flex items-end gap-px" style={{ height: 160 }}>
                  {series.map((point) => (
                    <div
                      key={point.date}
                      className="group flex h-full flex-1 flex-col justify-end"
                      style={{ minWidth: 3 }}
                      title={`${formatDateOnly(point.date)} · ${point.checkins} check-in · ${point.done} done · ${point.users} người`}
                    >
                      <div
                        className={`rounded-t transition ${
                          point.checkins === 0
                            ? "bg-slate-100"
                            : "bg-indigo-500 group-hover:bg-indigo-700"
                        }`}
                        style={{
                          // A zero day keeps a hairline so the gap is visibly a
                          // day with nothing, not a rendering glitch.
                          height:
                            point.checkins === 0
                              ? "2px"
                              : `${Math.max(3, (point.checkins / maxDaily) * 100)}%`,
                        }}
                      />
                    </div>
                  ))}
                </div>
                <div className="mt-2 flex justify-between text-xs text-slate-400">
                  {axisTicks(series).map((tick, index) => (
                    <span key={`${tick}-${index}`}>{tick}</span>
                  ))}
                </div>
              </div>
            )}
          </Section>

          <div className="grid grid-cols-1 gap-6 xl:grid-cols-2">
            <Section title="Cách check-in">
              {(data?.methodDistribution || []).length === 0 ? (
                <Empty />
              ) : (
                <div className="space-y-3">
                  {(data?.methodDistribution || []).map((row) => (
                    <div
                      key={row.method}
                      className="grid grid-cols-[110px_1fr_110px] items-center gap-3"
                    >
                      <MethodPill method={row.method} />
                      <Bar
                        percent={(row.count / maxMethod) * 100}
                        className="bg-indigo-600"
                      />
                      <span className="text-right text-sm text-slate-500">
                        <b className="text-slate-900">{formatNumber(row.count)}</b> ·{" "}
                        {row.percent}%
                      </span>
                    </div>
                  ))}
                </div>
              )}
            </Section>

            <Section title="Mood (Journal)">
              {(data?.moodDistribution || []).length === 0 ? (
                <Empty message="Chưa có check-in kiểu Journal trong khoảng này." />
              ) : (
                <div className="space-y-3">
                  {(data?.moodDistribution || []).map((row) => (
                    <div
                      key={row.mood}
                      className="grid grid-cols-[110px_1fr_110px] items-center gap-3"
                    >
                      <span className="text-sm font-medium text-slate-600">
                        {renderMood(row.mood)}
                      </span>
                      <Bar
                        percent={row.percent}
                        className={MOOD_BAR_COLORS[row.mood] || "bg-slate-400"}
                      />
                      <span className="text-right text-sm text-slate-500">
                        <b className="text-slate-900">{formatNumber(row.count)}</b> ·{" "}
                        {row.percent}%
                      </span>
                    </div>
                  ))}
                </div>
              )}
            </Section>
          </div>

          <Section
            title="Phân bố streak dài nhất"
            trailing="Tính trên mọi habit đã nhận, không giới hạn khoảng ngày"
          >
            {(data?.streakBuckets || []).length === 0 ? (
              <Empty />
            ) : (
              <div className="space-y-3">
                {(data?.streakBuckets || []).map((row) => (
                  <div
                    key={`${row.from}-${row.isOverflow}`}
                    className="grid grid-cols-[110px_1fr_90px] items-center gap-3"
                  >
                    <span className="text-sm font-medium text-slate-600">
                      {streakLabel(row.from, row.isOverflow)}
                    </span>
                    <Bar
                      percent={(row.count / maxStreak) * 100}
                      className="bg-emerald-600"
                    />
                    <span className="text-right text-sm font-semibold text-slate-900">
                      {formatNumber(row.count)}
                    </span>
                  </div>
                ))}
              </div>
            )}
          </Section>

          <Section title="Habit được check-in nhiều nhất" trailing="Top 20">
            {(data?.topHabits || []).length === 0 ? (
              <Empty />
            ) : (
              <div className="overflow-x-auto">
                <table className="w-full text-left text-sm">
                  <thead className="text-xs uppercase tracking-wide text-slate-400">
                    <tr>
                      <th className="py-2 pr-4">Habit</th>
                      <th className="py-2 pr-4 text-right">Check-in</th>
                      <th className="py-2 pr-4 text-right">Người dùng</th>
                      <th className="py-2 text-right">Tỉ lệ done</th>
                    </tr>
                  </thead>
                  <tbody className="divide-y divide-slate-100">
                    {(data?.topHabits || []).map((row) => (
                      <tr key={row.habitId}>
                        <td className="py-3 pr-4 text-slate-700">
                          {getTranslationValue(row.title || undefined, lang) || (
                            <span className="text-slate-400">
                              (habit đã xoá · {row.habitId})
                            </span>
                          )}
                        </td>
                        <td className="py-3 pr-4 text-right font-semibold text-slate-900">
                          {formatNumber(row.checkins)}
                        </td>
                        <td className="py-3 pr-4 text-right text-slate-600">
                          {formatNumber(row.users)}
                        </td>
                        <td className="py-3 text-right text-slate-600">
                          {row.doneRate}%
                        </td>
                      </tr>
                    ))}
                  </tbody>
                </table>
              </div>
            )}
          </Section>

          <Section
            title="Nhật ký gần đây"
            trailing={`${formatNumber(data?.notes.length)} bản ghi mới nhất`}
          >
            {(data?.notes || []).length === 0 ? (
              <Empty message="Chưa có nhật ký nào trong khoảng này." />
            ) : (
              <div className="space-y-3">
                {(data?.notes || []).map((row, index) => (
                  <article
                    key={`${row.userId}-${row.habitId}-${index}`}
                    className="rounded-xl border border-slate-100 bg-slate-50/60 p-4"
                  >
                    <div className="flex flex-wrap items-center gap-2 text-xs text-slate-500">
                      <MethodPill method={row.method} />
                      <span>{formatDateOnly(row.date)}</span>
                      {row.mood ? <span>{renderMood(row.mood)}</span> : null}
                      <Link
                        to={`/habit-checkins/user/${row.userId}`}
                        className="font-semibold text-indigo-600 hover:underline"
                      >
                        Xem người dùng
                      </Link>
                    </div>
                    <p className="mt-2 whitespace-pre-wrap text-sm text-slate-800">
                      {row.note}
                    </p>
                    <div className="mt-2 text-xs text-slate-500">
                      {getTranslationValue(row.title || undefined, lang) ||
                        row.habitId}
                    </div>
                  </article>
                ))}
              </div>
            )}
          </Section>
        </>
      ) : null}
    </div>
  );
}

/**
 * Turns the API's sparse day rows into a continuous day-by-day series.
 *
 * Range comes from the filter when there is one. For "Tất cả" there is no
 * window, so the series spans the first to the last day that actually has data
 * — the honest bounds of what we know.
 */
const buildSeries = (
  data: IHabitCheckinStatistics | null,
  range?: { startDate: string; endDate: string }
): IHabitDailyPoint[] => {
  const rows = data?.daily || [];
  if (rows.length === 0) return [];

  const byDay = new Map<string, IHabitDailyPoint>();
  for (const row of rows) byDay.set(row.date.slice(0, 10), row);

  // Array.from, not a spread: this project's tsconfig targets pre-ES2015 and
  // rejects iterating a Map's key iterator directly.
  const keys = Array.from(byDay.keys()).sort();
  const startKey = range?.startDate || keys[0];
  const endKey = range?.endDate || keys[keys.length - 1];

  const out: IHabitDailyPoint[] = [];
  // UTC arithmetic: check-in dates are stored at UTC midnight, so stepping in
  // local time would drift a day across a DST boundary and mis-align the bars.
  const cursor = new Date(`${startKey}T00:00:00Z`);
  const end = new Date(`${endKey}T00:00:00Z`);
  // Guard against a filter with the bounds inverted or unparseable.
  if (isNaN(cursor.getTime()) || isNaN(end.getTime()) || cursor > end) {
    return keys.map((key) => byDay.get(key)!);
  }
  while (cursor <= end) {
    const key = cursor.toISOString().slice(0, 10);
    out.push(
      byDay.get(key) ?? { date: key, checkins: 0, done: 0, users: 0 }
    );
    cursor.setUTCDate(cursor.getUTCDate() + 1);
  }
  return out;
};

/** Five evenly spaced date labels, so a tall bar can be placed without hovering. */
const axisTicks = (series: IHabitDailyPoint[]) => {
  if (series.length === 0) return [];
  const wanted = Math.min(5, series.length);
  const step = (series.length - 1) / Math.max(1, wanted - 1);
  return Array.from({ length: wanted }, (_, index) =>
    formatDateOnly(series[Math.round(index * step)].date)
  );
};

const streakLabel = (from: number, isOverflow: boolean) => {
  if (isOverflow) return `${from}+ ngày`;
  const spans: Record<number, string> = {
    1: "1 ngày",
    2: "2–3 ngày",
    4: "4–7 ngày",
    8: "8–14 ngày",
  };
  return spans[from] ?? `${from} ngày`;
};

const Section = ({
  title,
  trailing,
  children,
}: {
  title: string;
  trailing?: string;
  children: React.ReactNode;
}) => (
  <section className="rounded-2xl border border-slate-200 bg-white p-6 shadow-sm">
    <div className="mb-5 flex flex-wrap items-center justify-between gap-2 border-b border-slate-100 pb-4">
      <h2 className="text-base font-bold uppercase tracking-wide text-slate-900">
        {title}
      </h2>
      {trailing ? (
        <span className="text-sm text-slate-400">{trailing}</span>
      ) : null}
    </div>
    {children}
  </section>
);

const Bar = ({ percent, className }: { percent: number; className: string }) => (
  <div className="h-2 rounded-full bg-stone-100">
    <div
      className={`h-2 rounded-full ${className}`}
      style={{ width: `${Math.max(2, Math.min(100, percent))}%` }}
    />
  </div>
);

const Empty = ({ message = "Chưa có dữ liệu trong khoảng này." }) => (
  <p className="text-sm text-slate-500">{message}</p>
);

const StatCard = ({
  label,
  value,
  suffix = "",
  denominator,
  hint,
  delta,
}: {
  label: string;
  value: number | null;
  suffix?: string;
  denominator?: string;
  hint?: string;
  delta?: number | null;
}) => {
  const positive = (delta ?? 0) >= 0;
  return (
    <div className="rounded-2xl border border-slate-200 bg-white p-5 shadow-sm">
      <div className="text-sm font-medium text-slate-500">{label}</div>
      <div className="mt-3 flex items-end gap-1">
        <span className="text-3xl font-bold text-slate-950">
          {formatNumber(value)}
          {value === null ? "" : suffix}
        </span>
        {denominator ? (
          <span className="mb-1 text-lg font-semibold text-slate-400">
            / {denominator}
          </span>
        ) : null}
      </div>
      {delta === null || delta === undefined ? (
        hint ? <div className="mt-2 text-xs text-slate-400">{hint}</div> : null
      ) : (
        <div
          className={`mt-2 text-sm font-semibold ${
            positive ? "text-emerald-600" : "text-red-600"
          }`}
        >
          {positive ? "↑" : "↓"} {Math.abs(delta)}%{" "}
          <span className="font-normal text-slate-400">vs kỳ trước</span>
        </div>
      )}
    </div>
  );
};
