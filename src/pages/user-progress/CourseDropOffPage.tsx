import React, { useCallback, useEffect, useMemo, useState } from "react";
import { ArrowPathIcon, MapPinIcon } from "@heroicons/react/24/outline";
import { useSelector } from "react-redux";
import { RootState } from "../../store";
import { courseService } from "../../services/courseService";
import { userProgressService } from "../../services/userProgressService";
import { ICourse } from "../../types/interface/course.interface";
import { ICourseDropOff } from "../../types/interface/user-progress.interface";
import { getTranslationValue } from "../../utils/translation";

/**
 * Điểm dừng khoá học — histogram "user thường kẹt ở keypoint nào", gộp trên
 * TOÀN BỘ user của một khoá (khác trang User progress: trang đó soi từng
 * người, trang này trả lời câu hỏi biên tập: nội dung nào làm rơi người học).
 *
 * Nguồn số là `user_progress.stopAt` phía server — thứ push "còn bài học dở"
 * vẫn dùng hằng ngày — nên phủ mọi user từ trước tới nay, không phụ thuộc bản
 * app nào bắn event gì và không có TTL như user_events.
 */

/**
 * Các mốc "bao lâu không hoạt động thì tính là dừng hẳn". 0 đếm tất cả —
 * gồm cả người mới học hôm qua — nên nó đứng cuối và dán nhãn nói rõ điều đó.
 */
const STALE_OPTIONS: { value: number; label: string }[] = [
  { value: 7, label: "≥ 7 ngày không học" },
  { value: 14, label: "≥ 14 ngày không học" },
  { value: 30, label: "≥ 30 ngày không học" },
  { value: 0, label: "Tất cả (kể cả đang học)" },
];

const CourseDropOffPage: React.FC = () => {
  const lang = useSelector((state: RootState) => state.lang.code);

  const [courses, setCourses] = useState<ICourse[]>([]);
  const [coursesLoading, setCoursesLoading] = useState(true);
  const [courseId, setCourseId] = useState("");
  const [staleDays, setStaleDays] = useState(7);

  const [data, setData] = useState<ICourseDropOff | null>(null);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState("");

  useEffect(() => {
    let cancelled = false;
    (async () => {
      try {
        // take lớn thay vì phân trang: catalog cỡ chục khoá, và một dropdown
        // thiếu khoá sẽ đọc thành "khoá đó không có dữ liệu".
        const res = await courseService.getList({ isAll: true, take: 200 });
        if (cancelled) return;
        const items: ICourse[] = res.data?.items ?? [];
        items.sort((a, b) =>
          getTranslationValue(a.title, lang).localeCompare(
            getTranslationValue(b.title, lang),
            "vi"
          )
        );
        setCourses(items);
        // Tự chọn khoá đầu tiên: trang mở ra phải có số liệu ngay chứ không
        // phải một form trống chờ thao tác.
        if (items.length > 0) setCourseId((prev) => prev || items[0]._id);
      } catch {
        if (!cancelled) setError("Không tải được danh sách khoá học.");
      } finally {
        if (!cancelled) setCoursesLoading(false);
      }
    })();
    return () => {
      cancelled = true;
    };
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, []);

  const load = useCallback(async () => {
    if (!courseId) return;
    setLoading(true);
    setError("");
    try {
      const res = await userProgressService.getCourseDropOff({
        courseId,
        staleDays,
      });
      setData(res);
    } catch (err: any) {
      setError(err?.message ?? "Không tải được dữ liệu điểm dừng.");
      setData(null);
    } finally {
      setLoading(false);
    }
  }, [courseId, staleDays]);

  useEffect(() => {
    void load();
  }, [load]);

  const maxCount = useMemo(
    () => Math.max(1, ...(data?.rows ?? []).map((row) => row.count)),
    [data]
  );

  const rowLabel = (
    lessonTitle: ICourseDropOff["rows"][number]["lessonTitle"],
    keypointTitle: ICourseDropOff["rows"][number]["keypointTitle"]
  ) => {
    const lesson = lessonTitle
      ? getTranslationValue(lessonTitle, lang)
      : "(lesson đã xoá)";
    if (!keypointTitle) return lesson;
    return `${lesson} · ${getTranslationValue(keypointTitle, lang)}`;
  };

  const pct = (count: number) =>
    data && data.totalStuck > 0
      ? `${((count / data.totalStuck) * 100).toFixed(1)}%`
      : "—";

  return (
    <div className="p-6 space-y-4">
      <div>
        <h1 className="text-xl font-semibold text-slate-900 flex items-center gap-2">
          <MapPinIcon className="h-6 w-6 text-indigo-600" />
          Điểm dừng khoá học
        </h1>
        <p className="mt-1 text-sm text-slate-500">
          Mỗi khoá học, user đang kẹt ở keypoint nào — gộp trên toàn bộ user,
          đọc từ vị trí học dở phía server (không phụ thuộc event của app).
        </p>
      </div>

      <div className="flex flex-wrap items-end gap-3 rounded-2xl border border-slate-200 bg-white p-4">
        <label className="flex flex-col gap-1 text-xs text-slate-700">
          <span className="font-medium">Khoá học</span>
          <select
            value={courseId}
            onChange={(e) => setCourseId(e.target.value)}
            disabled={coursesLoading}
            className="min-w-[280px] rounded-lg border border-slate-200 px-2 py-2 text-sm"
          >
            {coursesLoading && <option value="">Đang tải…</option>}
            {courses.map((course) => (
              <option key={course._id} value={course._id}>
                {getTranslationValue(course.title, lang)}
              </option>
            ))}
          </select>
        </label>

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
          onClick={() => void load()}
          disabled={loading || !courseId}
          className="inline-flex items-center gap-1.5 rounded-lg border border-slate-200 px-3 py-2 text-sm text-slate-600 hover:bg-slate-50 disabled:opacity-50"
        >
          <ArrowPathIcon
            className={`h-4 w-4 ${loading ? "animate-spin" : ""}`}
          />
          Tải lại
        </button>
      </div>

      {error && (
        <div className="rounded-lg border border-red-200 bg-red-50 px-3 py-2.5 text-sm text-red-700">
          {error}
        </div>
      )}

      {data && !error && (
        <>
          <div className="grid grid-cols-1 gap-3 sm:grid-cols-3">
            <div className="rounded-2xl border border-slate-200 bg-white p-4">
              <p className="text-xs text-slate-500">Tổng user có progress</p>
              <p className="mt-1 text-2xl font-semibold text-slate-900">
                {data.totalInProgress}
              </p>
            </div>
            <div className="rounded-2xl border border-slate-200 bg-white p-4">
              <p className="text-xs text-slate-500">
                Đang kẹt{" "}
                {data.staleDays > 0 ? `(≥ ${data.staleDays} ngày)` : "(tất cả)"}
              </p>
              <p className="mt-1 text-2xl font-semibold text-amber-700">
                {data.totalStuck}
              </p>
            </div>
            <div className="rounded-2xl border border-slate-200 bg-white p-4">
              <p className="text-xs text-slate-500">Tỉ lệ kẹt / có progress</p>
              <p className="mt-1 text-2xl font-semibold text-slate-900">
                {data.totalInProgress > 0
                  ? `${((data.totalStuck / data.totalInProgress) * 100).toFixed(1)}%`
                  : "—"}
              </p>
            </div>
          </div>

          {data.rows.length === 0 ? (
            <div className="rounded-2xl border border-slate-200 bg-white p-8 text-center text-sm text-slate-500">
              Không có user nào kẹt lại theo bộ lọc này — hoặc khoá chưa có ai
              học dở, hoặc mọi người vẫn đang học (thử nới "dừng hẳn" về Tất
              cả).
            </div>
          ) : (
            <div className="rounded-2xl border border-slate-200 bg-white p-4">
              <p className="mb-3 text-xs font-medium text-slate-700">
                Điểm dừng, nhiều người nhất trước — % tính trên{" "}
                {data.totalStuck} user đang kẹt
              </p>
              <div className="space-y-2">
                {data.rows.map((row) => (
                  <div
                    key={`${row.lessonId}-${row.keypointId ?? "lesson"}`}
                    className="flex items-center gap-3"
                  >
                    <div className="w-2/5 min-w-0">
                      <p
                        className="truncate text-sm text-slate-800"
                        title={rowLabel(row.lessonTitle, row.keypointTitle)}
                      >
                        {rowLabel(row.lessonTitle, row.keypointTitle)}
                      </p>
                      {row.lessonType && (
                        <p className="text-[11px] text-slate-400">
                          {row.lessonType}
                          {!row.keypointId && " · dừng ở mức lesson"}
                        </p>
                      )}
                    </div>
                    <div className="flex-1">
                      <div className="h-5 rounded bg-slate-100">
                        <div
                          className="h-5 rounded bg-indigo-500"
                          style={{
                            width: `${Math.max(2, (row.count / maxCount) * 100)}%`,
                          }}
                        />
                      </div>
                    </div>
                    <div className="w-24 flex-shrink-0 text-right text-sm">
                      <span className="font-semibold text-slate-900">
                        {row.count}
                      </span>
                      <span className="ml-1 text-xs text-slate-500">
                        {pct(row.count)}
                      </span>
                    </div>
                  </div>
                ))}
              </div>
            </div>
          )}
        </>
      )}

      {loading && !data && (
        <div className="rounded-2xl border border-slate-200 bg-white p-8 text-center text-sm text-slate-500">
          Đang tải dữ liệu điểm dừng…
        </div>
      )}
    </div>
  );
};

export default CourseDropOffPage;
