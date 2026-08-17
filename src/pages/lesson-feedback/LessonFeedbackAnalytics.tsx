import { useCallback, useEffect, useState } from "react";
import { Pagination } from "@mui/material";
import {
  ArrowDownTrayIcon,
  InformationCircleIcon,
} from "@heroicons/react/24/outline";
import { useSelector } from "react-redux";
import { Link } from "react-router-dom";

import { RootState } from "../../store";
import { userFeedbackService } from "../../services/userFeedbackService";
import {
  FeedbackEntry,
  FeedbackType,
} from "../../types/enum/feedback.enum";
import {
  IUserFeedbackAbandonedRow,
  IUserFeedbackCommentPage,
  IUserFeedbackStatisticsOverview,
} from "../../types/interface/user-feedback.interface";
import { getTranslationValue } from "../../utils/translation";
import { useNotification } from "../../utils/hooks/useNotification";
import LessonFeedbackMetricCard from "./LessonFeedbackMetricCard";
import {
  ENTRY_LABELS,
  RATING_COLORS,
  REASON_COLORS,
  TYPE_LABELS,
  downloadXlsx,
  formatDateTime,
  formatNumber,
  presetRange,
  reasonLabel,
} from "./lesson-feedback-utils";

type DatePreset = "30" | "60" | "all" | "custom";

const COMMENTS_PAGE_SIZE = 10;

/**
 * Aggregate view over `user_feedback` — the end-of-lesson and abandon feedback
 * that until now could only be read one user at a time on the user-progress
 * screen.
 */
export default function LessonFeedbackAnalytics() {
  const lang = useSelector((state: RootState) => state.lang.code);
  const { showError, showSuccess } = useNotification();

  const [preset, setPreset] = useState<DatePreset>("30");
  const [range, setRange] = useState(() => presetRange(30));
  const [entry, setEntry] = useState<FeedbackEntry | "">("");
  const [type, setType] = useState<FeedbackType | "">("");

  const [overview, setOverview] = useState<IUserFeedbackStatisticsOverview | null>(null);
  const [comments, setComments] = useState<IUserFeedbackCommentPage | null>(null);
  const [commentPage, setCommentPage] = useState(1);
  const [loading, setLoading] = useState(true);
  const [exporting, setExporting] = useState(false);

  const query = useCallback(
    () => ({
      // "all" sends no dates at all, which is also what turns the deltas off
      // server-side — an all-time figure has no previous period.
      ...(preset === "all" ? {} : { startDate: range.startDate, endDate: range.endDate }),
      ...(entry ? { entry } : {}),
      ...(type ? { type } : {}),
    }),
    [preset, range, entry, type]
  );

  useEffect(() => {
    let cancelled = false;
    setLoading(true);
    Promise.all([
      userFeedbackService.getStatisticsOverview(query()),
      userFeedbackService.getStatisticsComments({
        ...query(),
        page: commentPage,
        take: COMMENTS_PAGE_SIZE,
      }),
    ])
      .then(([overviewData, commentData]) => {
        if (cancelled) return;
        setOverview(overviewData);
        setComments(commentData);
      })
      .catch((error: any) => {
        if (cancelled) return;
        showError(error?.response?.data?.message || "Không tải được thống kê feedback");
      })
      .finally(() => {
        if (!cancelled) setLoading(false);
      });
    return () => {
      cancelled = true;
    };
    // showError is recreated per render by the hook; depending on it would
    // refetch forever.
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [query, commentPage]);

  /** Exports exactly what the filters currently show, not the whole table. */
  const onExport = async () => {
    if (exporting) return;
    setExporting(true);
    try {
      const file = await userFeedbackService.exportStatistics(query());
      const stamp = preset === "all" ? "tat-ca" : `${range.startDate}_${range.endDate}`;
      downloadXlsx(file, `lesson-feedback_${stamp}.xlsx`);
      showSuccess("Xuất Excel thành công");
    } catch (error: any) {
      showError(error?.response?.data?.message || "Xuất Excel thất bại");
    } finally {
      setExporting(false);
    }
  };

  const onPresetChange = (value: DatePreset) => {
    setPreset(value);
    setCommentPage(1);
    if (value === "30" || value === "60") setRange(presetRange(Number(value)));
  };

  const metrics = overview?.metrics;
  const maxReason = Math.max(1, ...(overview?.reasonDistribution || []).map((r) => r.count));
  const totalRatings = (overview?.ratingDistribution || []).reduce((sum, r) => sum + r.count, 0);

  return (
    <div className="space-y-6 p-6">
      <header className="flex flex-wrap items-center justify-between gap-4">
        <div>
          <h1 className="text-2xl font-bold text-slate-900">Lesson Feedback</h1>
          <p className="mt-1 text-sm text-slate-500">
            Feedback cuối bài và lý do bỏ dở, tổng hợp từ toàn bộ người dùng.
          </p>
        </div>
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
                onChange={(event) => {
                  setRange((prev) => ({ ...prev, startDate: event.target.value }));
                  setCommentPage(1);
                }}
                className="rounded-lg border border-slate-200 px-2 py-1 text-sm"
              />
              <span className="text-slate-400">→</span>
              <input
                type="date"
                value={range.endDate}
                onChange={(event) => {
                  setRange((prev) => ({ ...prev, endDate: event.target.value }));
                  setCommentPage(1);
                }}
                className="rounded-lg border border-slate-200 px-2 py-1 text-sm"
              />
            </>
          ) : null}
          <span className="h-5 w-px bg-slate-200" />
          <select
            value={entry}
            onChange={(event) => {
              setEntry(event.target.value as FeedbackEntry | "");
              setCommentPage(1);
            }}
            className="rounded-lg border-0 bg-transparent text-sm font-semibold text-slate-900 outline-none"
          >
            <option value="">Mọi loại nội dung</option>
            <option value={FeedbackEntry.KEYPOINT}>Keypoint</option>
            <option value={FeedbackEntry.ROLEPLAY}>Roleplay</option>
          </select>
          <select
            value={type}
            onChange={(event) => {
              setType(event.target.value as FeedbackType | "");
              setCommentPage(1);
            }}
            className="rounded-lg border-0 bg-transparent text-sm font-semibold text-slate-900 outline-none"
          >
            <option value="">Hoàn thành + Bỏ dở</option>
            <option value={FeedbackType.COMPLETE}>Chỉ hoàn thành</option>
            <option value={FeedbackType.INCOMPLETE}>Chỉ bỏ dở</option>
          </select>
          <span className="h-5 w-px bg-slate-200" />
          <button
            type="button"
            onClick={onExport}
            disabled={exporting}
            className="inline-flex items-center gap-2 rounded-lg bg-indigo-600 px-3 py-1.5 text-sm font-semibold text-white transition hover:bg-indigo-700 disabled:cursor-not-allowed disabled:opacity-60"
          >
            <ArrowDownTrayIcon className="h-4 w-4" />
            {exporting ? "Đang xuất…" : "Xuất Excel"}
          </button>
        </div>
      </header>

      {/* The one caveat a reader must carry into every number below. */}
      {overview?.perUserLatestOnly ? (
        <div className="flex items-start gap-2 rounded-xl border border-amber-200 bg-amber-50 px-4 py-3 text-sm text-amber-900">
          <InformationCircleIcon className="mt-0.5 h-5 w-5 flex-none" />
          <span>
            Mỗi người dùng chỉ lưu <b>feedback mới nhất</b> của từng loại (keypoint/roleplay ×
            hoàn thành/bỏ dở), nên mọi con số ở đây là <b>số người</b>, không phải số lượt gửi.
            Muốn đếm theo lượt thì phải đổi cách lưu ở API.
          </span>
        </div>
      ) : null}

      {loading && !overview ? (
        <div className="rounded-2xl border border-slate-200 bg-white p-8 text-center text-sm text-slate-500">
          Đang tải…
        </div>
      ) : null}

      {metrics ? (
        <div className="grid grid-cols-1 gap-4 md:grid-cols-2 xl:grid-cols-4">
          <LessonFeedbackMetricCard
            label="Feedback (người)"
            value={metrics.records.value}
            delta={metrics.records.delta}
            hint="Không có kỳ trước để so sánh"
          />
          <LessonFeedbackMetricCard
            label="Bỏ dở"
            value={metrics.incomplete.value}
            delta={metrics.incomplete.delta}
            hint="Không có kỳ trước để so sánh"
          />
          <LessonFeedbackMetricCard
            label="Hoàn thành"
            value={metrics.complete.value}
            delta={metrics.complete.delta}
            hint="Không có kỳ trước để so sánh"
          />
          <LessonFeedbackMetricCard
            label="Điểm trung bình"
            value={metrics.averageOverall.value}
            denominator="5"
            hint={`Nội dung ${metrics.averageContent.value ?? "-"} · Trải nghiệm ${
              metrics.averageExperience.value ?? "-"
            }${
              metrics.unrated?.value
                ? ` · ${metrics.unrated.value} feedback chưa chấm điểm`
                : ""
            }`}
          />
        </div>
      ) : null}

      {overview ? (
        <section className="rounded-2xl border border-slate-200 bg-white p-6 shadow-sm">
          <div className="mb-6 flex items-center justify-between border-b border-slate-100 pb-4">
            <h2 className="text-base font-bold uppercase tracking-wide text-slate-900">
              Lý do bỏ dở
            </h2>
            <span className="text-sm text-slate-400">
              {formatNumber(metrics?.incomplete.value ?? 0)} feedback bỏ dở
            </span>
          </div>
          {(overview.reasonDistribution || []).length === 0 ? (
            <p className="text-sm text-slate-500">Chưa có feedback bỏ dở trong khoảng này.</p>
          ) : (
            <div className="space-y-4">
              {(overview.reasonDistribution || []).map((item, index) => (
                <div
                  key={item.reason}
                  className="grid grid-cols-[160px_1fr_110px] items-center gap-4"
                >
                  <span className="text-sm font-medium text-slate-600">
                    {reasonLabel(item.reason)}
                  </span>
                  <div className="h-2 rounded-full bg-stone-100">
                    <div
                      className={`h-2 rounded-full ${
                        REASON_COLORS[index % REASON_COLORS.length]
                      }`}
                      style={{ width: `${Math.max(2, (item.count / maxReason) * 100)}%` }}
                    />
                  </div>
                  <span className="text-right text-sm text-slate-500">
                    <b className="text-slate-900">{formatNumber(item.count)}</b> · {item.percent}%
                  </span>
                </div>
              ))}
            </div>
          )}
          <p className="mt-4 text-xs text-slate-400">
            Một feedback chọn được nhiều lý do, nên tổng phần trăm tính trên tổng lượt chọn.
          </p>
        </section>
      ) : null}

      {overview && (overview.ratingDistribution || []).length > 0 ? (
        <section className="rounded-2xl border border-slate-200 bg-white p-6 shadow-sm">
          <div className="mb-6 flex items-center justify-between border-b border-slate-100 pb-4">
            <h2 className="text-base font-bold uppercase tracking-wide text-slate-900">
              Phân bố điểm (feedback hoàn thành)
            </h2>
            <span className="text-sm text-slate-400">{formatNumber(totalRatings)} feedback</span>
          </div>
          <div className="space-y-4">
            {(overview.ratingDistribution || []).map((item) => (
              <div key={item.rating} className="grid grid-cols-[80px_1fr_110px] items-center gap-4">
                <span className="text-sm font-medium text-slate-600">{item.rating} sao</span>
                <div className="h-2 rounded-full bg-stone-100">
                  <div
                    className={`h-2 rounded-full ${
                      RATING_COLORS[Math.min(item.rating, 5) - 1] || "bg-indigo-600"
                    }`}
                    style={{
                      width: `${Math.max(2, (item.count / Math.max(1, totalRatings)) * 100)}%`,
                    }}
                  />
                </div>
                <span className="text-right text-sm text-slate-500">
                  <b className="text-slate-900">{formatNumber(item.count)}</b> ·{" "}
                  {Math.round((item.count / Math.max(1, totalRatings)) * 1000) / 10}%
                </span>
              </div>
            ))}
          </div>
        </section>
      ) : null}

      {overview ? (
        <section className="rounded-2xl border border-slate-200 bg-white p-6 shadow-sm">
          <div className="mb-4 flex items-center justify-between border-b border-slate-100 pb-4">
            <h2 className="text-base font-bold uppercase tracking-wide text-slate-900">
              Nội dung bị bỏ dở nhiều nhất
            </h2>
            <span className="text-sm text-slate-400">Top 20</span>
          </div>
          {(overview.topAbandoned || []).length === 0 ? (
            <p className="text-sm text-slate-500">Chưa có dữ liệu.</p>
          ) : (
            <div className="overflow-x-auto">
              <table className="w-full text-left text-sm">
                <thead className="text-xs uppercase tracking-wide text-slate-400">
                  <tr>
                    <th className="py-2 pr-4">Khoá học</th>
                    <th className="py-2 pr-4">Bài học</th>
                    <th className="py-2 pr-4">Keypoint</th>
                    <th className="py-2 pr-4">Loại</th>
                    <th className="py-2 pr-4">Lý do phổ biến</th>
                    <th className="py-2 text-right">Số người</th>
                  </tr>
                </thead>
                <tbody className="divide-y divide-slate-100">
                  {(overview.topAbandoned || []).map((row: IUserFeedbackAbandonedRow, index) => (
                    <tr key={`${row.courseId}-${row.lessonId}-${row.keypointId ?? index}`}>
                      <td className="py-3 pr-4 text-slate-700">
                        {getTranslationValue(row.courseTitle, lang) || row.courseId}
                      </td>
                      <td className="py-3 pr-4 text-slate-700">
                        {getTranslationValue(row.lessonTitle, lang) || row.lessonId}
                      </td>
                      <td className="py-3 pr-4 text-slate-500">
                        {getTranslationValue(row.keypointTitle, lang) || "-"}
                      </td>
                      <td className="py-3 pr-4 text-slate-500">{ENTRY_LABELS[row.entry]}</td>
                      <td className="py-3 pr-4 text-slate-500">
                        {row.topReasons?.length
                          ? row.topReasons
                              .map((r) => `${reasonLabel(r.reason)} (${r.count})`)
                              .join(", ")
                          : "-"}
                      </td>
                      <td className="py-3 text-right font-semibold text-slate-900">
                        {formatNumber(row.count)}
                      </td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>
          )}
        </section>
      ) : null}

      <section className="rounded-2xl border border-slate-200 bg-white p-6 shadow-sm">
        <div className="mb-4 flex items-center justify-between border-b border-slate-100 pb-4">
          <h2 className="text-base font-bold uppercase tracking-wide text-slate-900">
            Bình luận của người dùng
          </h2>
          <span className="text-sm text-slate-400">
            {formatNumber(comments?.totalItems ?? 0)} feedback có nội dung
          </span>
        </div>
        {!comments || comments.items.length === 0 ? (
          <p className="text-sm text-slate-500">Chưa có bình luận nào trong khoảng này.</p>
        ) : (
          <>
            <div className="space-y-3">
              {comments.items.map((row, index) => (
                <article
                  key={`${row.userId}-${row.entry}-${row.type}-${index}`}
                  className="rounded-xl border border-slate-100 bg-slate-50/60 p-4"
                >
                  <div className="flex flex-wrap items-center gap-2 text-xs text-slate-500">
                    <span className="rounded-full bg-slate-200 px-2 py-0.5 font-semibold text-slate-700">
                      {ENTRY_LABELS[row.entry]} · {TYPE_LABELS[row.type]}
                    </span>
                    <span>{formatDateTime(row.submittedAt)}</span>
                    <Link
                      to={`/progress/user/${row.userId}`}
                      className="font-semibold text-indigo-600 hover:underline"
                    >
                      Xem người dùng
                    </Link>
                  </div>
                  <p className="mt-2 text-sm text-slate-800">{row.comment}</p>
                  <div className="mt-2 text-xs text-slate-500">
                    {getTranslationValue(row.courseTitle, lang) || row.courseId}
                    {row.keypointTitle
                      ? ` · ${getTranslationValue(row.keypointTitle, lang)}`
                      : ""}
                    {row.reasons?.length
                      ? ` · ${row.reasons.map(reasonLabel).join(", ")}`
                      : ""}
                    {row.overallRating ? ` · ${row.overallRating}/5` : ""}
                  </div>
                </article>
              ))}
            </div>
            {comments.totalPages > 1 ? (
              <div className="mt-4 flex justify-end">
                <Pagination
                  count={comments.totalPages}
                  page={comments.currentPage}
                  onChange={(_, page) => setCommentPage(page)}
                  size="small"
                />
              </div>
            ) : null}
          </>
        )}
      </section>
    </div>
  );
}
