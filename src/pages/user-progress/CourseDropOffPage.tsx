import React, { useCallback, useEffect, useMemo, useState } from "react";
import {
  ArrowPathIcon,
  MagnifyingGlassIcon,
  MapPinIcon,
} from "@heroicons/react/24/outline";
import {
  Bar,
  BarChart,
  CartesianGrid,
  Cell,
  LabelList,
  ResponsiveContainer,
  Tooltip,
  XAxis,
  YAxis,
} from "recharts";
import { useSelector } from "react-redux";
import { RootState } from "../../store";
import {
  AXIS_PROPS,
  CHART_INK,
  GRID_PROPS,
  SERIES,
} from "../../components/dashboard/dashboardTheme";
import { userProgressService } from "../../services/userProgressService";
import {
  ICourseDropOff,
  IDropOffOverview,
} from "../../types/interface/user-progress.interface";
import { ITranslation } from "../../utils/translate";
import { getTranslationValue } from "../../utils/translation";

/**
 * Điểm dừng khoá học — master–detail: trái là MỌI khoá xếp theo số user kẹt
 * (tự nó là bảng xếp hạng "khoá nào đang rơi người"), phải là mổ xẻ khoá được
 * chọn. Không phải dropdown: danh sách kèm con số là thứ cho thấy vấn đề
 * TRƯỚC khi phải chọn gì — dropdown bắt người xem đoán mò nên mở khoá nào.
 *
 * Nguồn số là `user_progress.stopAt` phía server (thứ push "còn bài học dở"
 * vẫn dùng) — phủ mọi user, không TTL, không phụ thuộc event của app.
 */

const STALE_OPTIONS: { value: number; label: string }[] = [
  { value: 7, label: "≥ 7 ngày không học" },
  { value: 14, label: "≥ 14 ngày không học" },
  { value: 30, label: "≥ 30 ngày không học" },
  { value: 0, label: "Tất cả (kể cả đang học)" },
];

/** Nhãn khoá/lesson đã xoá — vẫn được đếm vì user vẫn kẹt trong đó. */
const DELETED = "(đã xoá)";

const CourseDropOffPage: React.FC = () => {
  const lang = useSelector((state: RootState) => state.lang.code);

  const [staleDays, setStaleDays] = useState(7);
  const [overview, setOverview] = useState<IDropOffOverview | null>(null);
  const [overviewError, setOverviewError] = useState("");
  const [overviewLoading, setOverviewLoading] = useState(true);
  const [search, setSearch] = useState("");
  const [courseId, setCourseId] = useState("");

  const [detail, setDetail] = useState<ICourseDropOff | null>(null);
  const [detailLoading, setDetailLoading] = useState(false);
  const [detailError, setDetailError] = useState("");

  const tr = useCallback(
    (title: ITranslation | null | undefined) =>
      title ? getTranslationValue(title, lang) : DELETED,
    [lang]
  );

  const loadOverview = useCallback(async () => {
    setOverviewLoading(true);
    setOverviewError("");
    try {
      const res = await userProgressService.getDropOffOverview({ staleDays });
      setOverview(res);
      // Tự chọn khoá kẹt nhiều nhất khi chưa chọn gì — trang mở ra là có
      // ngay bức tranh của ca nặng nhất, không phải một khung trống.
      setCourseId(
        (prev) => prev || res.courses.find((c) => c.totalStuck > 0)?.courseId || res.courses[0]?.courseId || ""
      );
    } catch (err: any) {
      setOverviewError(err?.message ?? "Không tải được danh sách khoá học.");
    } finally {
      setOverviewLoading(false);
    }
  }, [staleDays]);

  useEffect(() => {
    void loadOverview();
  }, [loadOverview]);

  const loadDetail = useCallback(async () => {
    if (!courseId) return;
    setDetailLoading(true);
    setDetailError("");
    try {
      const res = await userProgressService.getCourseDropOff({
        courseId,
        staleDays,
      });
      setDetail(res);
    } catch (err: any) {
      setDetailError(err?.message ?? "Không tải được dữ liệu điểm dừng.");
      setDetail(null);
    } finally {
      setDetailLoading(false);
    }
  }, [courseId, staleDays]);

  useEffect(() => {
    void loadDetail();
  }, [loadDetail]);

  const filteredCourses = useMemo(() => {
    const list = overview?.courses ?? [];
    const query = search.trim().toLowerCase();
    if (!query) return list;
    return list.filter((course) =>
      tr(course.title).toLowerCase().includes(query)
    );
  }, [overview, search, tr]);

  const maxStuck = useMemo(
    () => Math.max(1, ...(overview?.courses ?? []).map((c) => c.totalStuck)),
    [overview]
  );

  /** Gộp điểm dừng theo LESSON — biểu đồ "rơi ở bài nào" (thô hơn keypoint). */
  const byLesson = useMemo(() => {
    if (!detail) return [];
    const map = new Map<string, { name: string; count: number }>();
    for (const row of detail.rows) {
      const key = row.lessonId;
      const entry = map.get(key) ?? { name: tr(row.lessonTitle), count: 0 };
      entry.count += row.count;
      map.set(key, entry);
    }
    return Array.from(map.values())
      .sort((a, b) => b.count - a.count)
      .slice(0, 10);
  }, [detail, tr]);

  const maxRowCount = useMemo(
    () => Math.max(1, ...(detail?.rows ?? []).map((row) => row.count)),
    [detail]
  );

  const pctOfStuck = (count: number) =>
    detail && detail.totalStuck > 0
      ? `${((count / detail.totalStuck) * 100).toFixed(1)}%`
      : "—";

  const selectedTitle = tr(
    overview?.courses.find((c) => c.courseId === courseId)?.title
  );

  return (
    <div className="p-6 space-y-4">
      <div className="flex flex-wrap items-end justify-between gap-3">
        <div>
          <h1 className="text-xl font-semibold text-slate-900 flex items-center gap-2">
            <MapPinIcon className="h-6 w-6 text-indigo-600" />
            Điểm dừng khoá học
          </h1>
          <p className="mt-1 text-sm text-slate-500">
            User đang kẹt ở keypoint nào — gộp trên toàn bộ user, đọc từ vị trí
            học dở phía server.
          </p>
        </div>

        <div className="flex items-end gap-3">
          <label className="flex flex-col gap-1 text-xs text-slate-700">
            <span className="font-medium">Tính là "dừng hẳn" khi</span>
            <select
              value={staleDays}
              onChange={(e) => setStaleDays(Number(e.target.value))}
              className="rounded-lg border border-slate-200 px-2 py-2 text-sm"
            >
              {STALE_OPTIONS.map((option) => (
                <option key={option.value} value={option.value}>
                  {option.label}
                </option>
              ))}
            </select>
          </label>
          <button
            type="button"
            onClick={() => {
              void loadOverview();
              void loadDetail();
            }}
            disabled={overviewLoading || detailLoading}
            className="inline-flex items-center gap-1.5 rounded-lg border border-slate-200 px-3 py-2 text-sm text-slate-600 hover:bg-slate-50 disabled:opacity-50"
          >
            <ArrowPathIcon
              className={`h-4 w-4 ${overviewLoading || detailLoading ? "animate-spin" : ""}`}
            />
            Tải lại
          </button>
        </div>
      </div>

      <div className="flex gap-4 items-start">
        {/* ── Danh sách khoá: xếp theo số kẹt, tự nó là bảng xếp hạng ── */}
        <div className="w-96 flex-shrink-0 rounded-2xl border border-slate-200 bg-white">
          <div className="border-b border-slate-100 p-3">
            <div className="relative">
              <MagnifyingGlassIcon className="pointer-events-none absolute left-2.5 top-2.5 h-4 w-4 text-slate-400" />
              <input
                value={search}
                onChange={(e) => setSearch(e.target.value)}
                placeholder="Tìm khoá học…"
                className="w-full rounded-lg border border-slate-200 py-2 pl-8 pr-2 text-sm"
              />
            </div>
          </div>

          {overviewError && (
            <p className="p-4 text-sm text-red-600">{overviewError}</p>
          )}
          {overviewLoading && !overview && (
            <p className="p-4 text-sm text-slate-500">Đang tải…</p>
          )}

          <div className="max-h-[calc(100vh-260px)] overflow-y-auto">
            {filteredCourses.map((course) => {
              const selected = course.courseId === courseId;
              return (
                <button
                  key={course.courseId}
                  type="button"
                  onClick={() => setCourseId(course.courseId)}
                  className={`block w-full border-b border-slate-50 px-3 py-2.5 text-left hover:bg-slate-50 ${
                    selected ? "bg-indigo-50 hover:bg-indigo-50" : ""
                  }`}
                >
                  <div className="flex items-center justify-between gap-2">
                    <p
                      className={`min-w-0 truncate text-sm ${
                        selected
                          ? "font-semibold text-indigo-900"
                          : "text-slate-800"
                      }`}
                      title={tr(course.title)}
                    >
                      {tr(course.title)}
                    </p>
                    <p className="flex-shrink-0 text-sm">
                      <span className="font-semibold text-amber-700">
                        {course.totalStuck}
                      </span>
                      <span className="text-xs text-slate-400">
                        {" "}
                        / {course.totalInProgress}
                      </span>
                    </p>
                  </div>
                  {/* Thanh so sánh GIỮA các khoá — cùng mẫu số (khoá kẹt nhiều
                      nhất), nên liếc dọc danh sách là thấy khoá nào nặng. */}
                  <div className="mt-1.5 h-1.5 rounded bg-slate-100">
                    <div
                      className="h-1.5 rounded bg-amber-500"
                      style={{
                        width: `${Math.max(course.totalStuck > 0 ? 2 : 0, (course.totalStuck / maxStuck) * 100)}%`,
                      }}
                    />
                  </div>
                </button>
              );
            })}
            {!overviewLoading && filteredCourses.length === 0 && (
              <p className="p-4 text-sm text-slate-500">
                Không có khoá nào khớp "{search.trim()}".
              </p>
            )}
          </div>
        </div>

        {/* ── Chi tiết khoá được chọn ── */}
        <div className="min-w-0 flex-1 space-y-4">
          {detailError && (
            <div className="rounded-lg border border-red-200 bg-red-50 px-3 py-2.5 text-sm text-red-700">
              {detailError}
            </div>
          )}
          {detailLoading && !detail && (
            <div className="rounded-2xl border border-slate-200 bg-white p-8 text-center text-sm text-slate-500">
              Đang tải dữ liệu điểm dừng…
            </div>
          )}

          {detail && !detailError && (
            <>
              <div className="grid grid-cols-1 gap-3 sm:grid-cols-3">
                <div className="rounded-2xl border border-slate-200 bg-white p-4">
                  <p className="truncate text-xs text-slate-500" title={selectedTitle}>
                    {selectedTitle} — tổng có progress
                  </p>
                  <p className="mt-1 text-2xl font-semibold text-slate-900">
                    {detail.totalInProgress}
                  </p>
                </div>
                <div className="rounded-2xl border border-slate-200 bg-white p-4">
                  <p className="text-xs text-slate-500">
                    Đang kẹt{" "}
                    {detail.staleDays > 0
                      ? `(≥ ${detail.staleDays} ngày)`
                      : "(tất cả)"}
                  </p>
                  <p className="mt-1 text-2xl font-semibold text-amber-700">
                    {detail.totalStuck}
                  </p>
                </div>
                <div className="rounded-2xl border border-slate-200 bg-white p-4">
                  <p className="text-xs text-slate-500">Tỉ lệ kẹt / có progress</p>
                  <p className="mt-1 text-2xl font-semibold text-slate-900">
                    {detail.totalInProgress > 0
                      ? `${((detail.totalStuck / detail.totalInProgress) * 100).toFixed(1)}%`
                      : "—"}
                  </p>
                </div>
              </div>

              <div className="grid grid-cols-1 gap-4 xl:grid-cols-2">
                {/* ── Kẹt theo lesson ── */}
                <div className="rounded-2xl border border-slate-200 bg-white p-4">
                  <p className="text-sm font-semibold text-slate-900">
                    Kẹt theo bài học
                  </p>
                  <p className="mb-2 text-xs text-slate-500">
                    Gộp mọi keypoint về lesson của nó — top 10
                  </p>
                  {byLesson.length === 0 ? (
                    <p className="py-8 text-center text-sm text-slate-500">
                      Không có dữ liệu theo bộ lọc này.
                    </p>
                  ) : (
                    <ResponsiveContainer
                      width="100%"
                      height={Math.max(160, byLesson.length * 34)}
                    >
                      <BarChart
                        data={byLesson}
                        layout="vertical"
                        margin={{ top: 0, right: 40, bottom: 0, left: 0 }}
                      >
                        <CartesianGrid {...GRID_PROPS} horizontal={false} vertical />
                        <XAxis type="number" allowDecimals={false} {...AXIS_PROPS} />
                        <YAxis
                          type="category"
                          dataKey="name"
                          width={170}
                          {...AXIS_PROPS}
                          tickFormatter={(value: string) =>
                            value.length > 24 ? `${value.slice(0, 23)}…` : value
                          }
                        />
                        <Tooltip
                          formatter={(value) => [value as number, "user kẹt"]}
                          contentStyle={{ fontSize: 12 }}
                        />
                        <Bar dataKey="count" fill={SERIES.active} radius={[0, 4, 4, 0]}>
                          <LabelList
                            dataKey="count"
                            position="right"
                            style={{ fill: CHART_INK.text, fontSize: 12 }}
                          />
                        </Bar>
                      </BarChart>
                    </ResponsiveContainer>
                  )}
                </div>

                {/* ── Kẹt bao lâu rồi ── */}
                <div className="rounded-2xl border border-slate-200 bg-white p-4">
                  <p className="text-sm font-semibold text-slate-900">
                    Kẹt bao lâu rồi
                  </p>
                  <p className="mb-2 text-xs text-slate-500">
                    Mọi người đang học dở, tính từ lần học cuối — không phụ
                    thuộc bộ lọc "dừng hẳn"
                  </p>
                  <ResponsiveContainer width="100%" height={220}>
                    <BarChart
                      data={detail.staleness}
                      margin={{ top: 16, right: 8, bottom: 0, left: -20 }}
                    >
                      <CartesianGrid {...GRID_PROPS} />
                      <XAxis dataKey="bucket" {...AXIS_PROPS} />
                      <YAxis allowDecimals={false} {...AXIS_PROPS} />
                      <Tooltip
                        formatter={(value) => [value as number, "user"]}
                        contentStyle={{ fontSize: 12 }}
                      />
                      <Bar dataKey="count" radius={[4, 4, 0, 0]}>
                        <LabelList
                          dataKey="count"
                          position="top"
                          style={{ fill: CHART_INK.text, fontSize: 12 }}
                        />
                        {/* Càng lâu càng cam: cột "90+ ngày" là nhóm gần như đã
                            mất, và màu phải nói điều đó trước con số. */}
                        {detail.staleness.map((entry, index) => (
                          <Cell
                            key={entry.bucket}
                            fill={index < 2 ? SERIES.new : SERIES.active}
                          />
                        ))}
                      </Bar>
                    </BarChart>
                  </ResponsiveContainer>
                </div>
              </div>

              {/* ── Điểm dừng chi tiết (lesson · keypoint) ── */}
              {detail.rows.length === 0 ? (
                <div className="rounded-2xl border border-slate-200 bg-white p-8 text-center text-sm text-slate-500">
                  Không có user nào kẹt lại theo bộ lọc này — thử nới "dừng
                  hẳn" về Tất cả.
                </div>
              ) : (
                <div className="rounded-2xl border border-slate-200 bg-white p-4">
                  <p className="text-sm font-semibold text-slate-900">
                    Điểm dừng chi tiết
                  </p>
                  <p className="mb-3 text-xs text-slate-500">
                    Từng keypoint, nhiều người nhất trước — % tính trên{" "}
                    {detail.totalStuck} user đang kẹt
                  </p>
                  <div className="space-y-2">
                    {detail.rows.map((row) => (
                      <div
                        key={`${row.lessonId}-${row.keypointId ?? "lesson"}`}
                        className="flex items-center gap-3"
                      >
                        <div className="w-2/5 min-w-0">
                          <p
                            className="truncate text-sm text-slate-800"
                            title={`${tr(row.lessonTitle)}${row.keypointTitle ? ` · ${tr(row.keypointTitle)}` : ""}`}
                          >
                            {row.keypointTitle
                              ? tr(row.keypointTitle)
                              : tr(row.lessonTitle)}
                          </p>
                          <p className="truncate text-[11px] text-slate-400">
                            {tr(row.lessonTitle)}
                            {row.lessonType ? ` · ${row.lessonType}` : ""}
                            {!row.keypointId && " · dừng ở mức lesson"}
                          </p>
                        </div>
                        <div className="flex-1">
                          <div className="h-5 rounded bg-slate-100">
                            <div
                              className="h-5 rounded bg-indigo-500"
                              style={{
                                width: `${Math.max(2, (row.count / maxRowCount) * 100)}%`,
                              }}
                            />
                          </div>
                        </div>
                        <div className="w-24 flex-shrink-0 text-right text-sm">
                          <span className="font-semibold text-slate-900">
                            {row.count}
                          </span>
                          <span className="ml-1 text-xs text-slate-500">
                            {pctOfStuck(row.count)}
                          </span>
                        </div>
                      </div>
                    ))}
                  </div>
                </div>
              )}
            </>
          )}
        </div>
      </div>
    </div>
  );
};

export default CourseDropOffPage;
