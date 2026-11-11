import React, { useCallback, useEffect, useMemo, useState } from "react";
import {
  ArrowPathIcon,
  CheckBadgeIcon,
  ExclamationTriangleIcon,
} from "@heroicons/react/24/outline";
import {
  CartesianGrid,
  Line,
  LineChart,
  ReferenceDot,
  ResponsiveContainer,
  Tooltip,
  XAxis,
  YAxis,
} from "recharts";
import {
  AXIS_PROPS,
  GRID_PROPS,
  MAX_COMPARED_VERSIONS,
  VERSION_SERIES,
} from "../../components/dashboard/dashboardTheme";
import {
  ComparableCourse,
  VersionComparison,
  VersionRow,
  versionAnalyticsService,
} from "../../services/versionAnalyticsService";
import {
  deltaOf,
  formatDateVi,
  formatDelta,
  formatMetric,
} from "../../utils/versionDelta";

/**
 * So sánh phiên bản nội dung của một khoá.
 *
 * Việc của trang: một bản mới đã sửa nội dung — nó học tốt hơn bản cũ hay
 * không, và rơi ở bài nào. Nên trang KHÔNG phải một dashboard tổng: nó là một
 * bảng đối chiếu có bản mốc, cộng hai đường cong trả lời "rơi ở đâu".
 *
 * Ba quy ước không được đổi, vì đổi là đổi luôn câu trả lời:
 *
 *  - **Mẫu số của đường giữ chân là cố định** (người đã mở khoá), không reset
 *    ở mỗi bài. Chia lại theo từng bài sẽ làm đường gần như phẳng và xoá đúng
 *    chỗ rơi.
 *  - **Mỗi bản đọc thứ tự bài của CHÍNH NÓ.** Bản gộp 12 bài xuống 10 thì
 *    "bài số 7" của hai bản là hai bài khác nhau; trục X là vị trí học, và
 *    mỗi đường dừng ở bài cuối của bản đó.
 *  - **Màu theo phiên bản, không theo thứ hạng.** Slot màu lấy theo vị trí
 *    trong toàn bộ danh sách, nên bỏ tích một bản không sơn lại các bản khác.
 *
 * `null` không phải 0: bản đóng băng mà chưa phát hành hiện dấu gạch, vì chưa
 * ai học nó — in 0 vào đó là bảo người xem rằng bản ấy tệ.
 */

const ENVS = [
  { value: "dev", label: "Dev" },
  { value: "production", label: "Production" },
];

const TONE_CLASS: Record<string, string> = {
  good: "text-emerald-600",
  bad: "text-red-600",
  neutral: "text-slate-400",
};

const VersionComparisonPage: React.FC = () => {
  const [courses, setCourses] = useState<ComparableCourse[]>([]);
  const [courseId, setCourseId] = useState("");
  const [env, setEnv] = useState("dev");
  const [data, setData] = useState<VersionComparison | null>(null);
  const [selected, setSelected] = useState<string[]>([]);
  const [baseline, setBaseline] = useState("");
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState("");

  useEffect(() => {
    let alive = true;
    versionAnalyticsService
      .courses()
      .then((list) => {
        if (!alive) return;
        setCourses(list);
        setCourseId((current) => current || list[0]?.id || "");
      })
      .catch(() => alive && setError("Không tải được danh sách khoá."));

    return () => {
      alive = false;
    };
  }, []);

  const load = useCallback(async () => {
    if (!courseId) return;
    setLoading(true);
    setError("");
    try {
      const next = await versionAnalyticsService.compare(courseId, env);
      setData(next);
      // Mặc định: bản đang phát hành làm mốc, cộng bản phát hành ngay trước
      // nó. Đó là câu hỏi người ta mở trang này để hỏi — "bản vừa đẩy có khá
      // hơn bản trước không" — nên không bắt tích tay mới thấy gì.
      const published = (next.versions ?? []).filter((v) => v.publishedAt);
      const live = published.find((v) => v.live) ?? published[published.length - 1];
      const previous = published[published.indexOf(live) - 1];
      setBaseline(previous?.tag ?? live?.tag ?? "");
      setSelected(
        [previous?.tag, live?.tag].filter((tag): tag is string => !!tag),
      );
    } catch {
      setError("Không tải được số liệu của khoá này.");
      setData(null);
    } finally {
      setLoading(false);
    }
  }, [courseId, env]);

  useEffect(() => {
    load();
  }, [load]);

  const versions = data?.versions ?? [];

  /** Slot màu cố định theo vị trí trong TOÀN BỘ danh sách. */
  const colorOf = useCallback(
    (tag: string) => {
      const at = versions.findIndex((v) => v.tag === tag);

      return VERSION_SERIES[at % VERSION_SERIES.length];
    },
    [versions],
  );

  const shown = useMemo(
    () => versions.filter((v) => selected.includes(v.tag)),
    [versions, selected],
  );

  const baseRow = useMemo(
    () => versions.find((v) => v.tag === baseline) ?? null,
    [versions, baseline],
  );

  const toggle = (tag: string) => {
    setSelected((current) => {
      if (current.includes(tag)) {
        // Bảng cần tối thiểu 2 cột để còn là một phép so sánh.
        if (current.length <= 2) return current;
        const next = current.filter((t) => t !== tag);
        if (tag === baseline) setBaseline(next[0]);

        return next;
      }
      if (current.length >= MAX_COMPARED_VERSIONS) return current;

      return [...current, tag];
    });
  };

  return (
    <div className="min-h-screen bg-[#f9f9f7] px-6 py-6">
      <div className="mx-auto max-w-[1400px] space-y-6">
        <Header
          courses={courses}
          courseId={courseId}
          onCourse={setCourseId}
          env={env}
          onEnv={setEnv}
          onReload={load}
          loading={loading}
          generatedAt={data?.generatedAt}
        />

        {error ? <Banner tone="error" text={error} /> : null}

        {!error && !loading && data && versions.length < 2 ? (
          <Banner
            tone="info"
            text={`Khoá này mới có ${versions.length} phiên bản. Cần từ 2 bản trở lên mới so sánh được — đánh thêm tag ở trang Course.`}
          />
        ) : null}

        {data && versions.length >= 2 ? (
          <>
            <KpiRow data={data} />

            <VersionLine
              versions={versions}
              selected={selected}
              baseline={baseline}
              onToggle={toggle}
              onBaseline={setBaseline}
              colorOf={colorOf}
            />

            {shown.length >= 2 && baseRow ? (
              <>
                <MetricTable
                  data={data}
                  shown={shown}
                  baseRow={baseRow}
                  colorOf={colorOf}
                />
                <RetentionChart shown={shown} colorOf={colorOf} />
                <DepthChart shown={shown} colorOf={colorOf} />
              </>
            ) : (
              <Banner
                tone="info"
                text="Chọn ít nhất 2 phiên bản ở trên để hiện bảng so sánh."
              />
            )}

            <p className="pb-4 text-xs leading-relaxed text-[#898781]">
              Số liệu gán theo cửa sổ thời gian mà mỗi bản đang được phát hành —
              một event học tập thuộc về bản đang live lúc nó xảy ra. Sổ cửa sổ
              chỉ bắt đầu được ghi từ khi tính năng này lên, nên quãng trước đó
              không có số. Bản đóng băng mà chưa phát hành hiện dấu gạch, không
              phải 0.
            </p>
          </>
        ) : null}
      </div>
    </div>
  );
};

// ------------------------------------------------------------------- header

const Header: React.FC<{
  courses: ComparableCourse[];
  courseId: string;
  onCourse: (id: string) => void;
  env: string;
  onEnv: (env: string) => void;
  onReload: () => void;
  loading: boolean;
  generatedAt?: string;
}> = ({ courses, courseId, onCourse, env, onEnv, onReload, loading, generatedAt }) => (
  <div className="space-y-4">
    <p className="text-xs font-medium uppercase tracking-wide text-[#898781]">
      HDDhistory · Vận hành nội dung
    </p>
    <div className="flex flex-wrap items-end justify-between gap-4">
      <div className="max-w-2xl space-y-2">
        <h1 className="text-2xl font-semibold text-[#0b0b0b]">
          So sánh phiên bản khoá học
        </h1>
        <p className="text-sm leading-relaxed text-[#52514e]">
          Mỗi bản cập nhật của khoá học được đo bằng 7 chỉ số học tập. Chọn từ 2
          phiên bản trở lên để đối chiếu trực tiếp và xem thay đổi so với bản
          mốc.
        </p>
      </div>
      <div className="flex flex-wrap items-center gap-2">
        <select
          value={courseId}
          onChange={(e) => onCourse(e.target.value)}
          aria-label="Khoá học"
          className="h-9 min-w-[240px] rounded-lg border border-[#e1e0d9] bg-white px-3 text-sm text-[#0b0b0b]"
        >
          {courses.length === 0 ? <option value="">Chưa có khoá nào có tag</option> : null}
          {courses.map((course) => (
            <option key={course.id} value={course.id}>
              {course.title}
            </option>
          ))}
        </select>
        <select
          value={env}
          onChange={(e) => onEnv(e.target.value)}
          aria-label="Môi trường"
          className="h-9 rounded-lg border border-[#e1e0d9] bg-white px-3 text-sm text-[#0b0b0b]"
        >
          {ENVS.map((option) => (
            <option key={option.value} value={option.value}>
              {option.label}
            </option>
          ))}
        </select>
        <button
          type="button"
          onClick={onReload}
          disabled={loading}
          className="flex h-9 items-center gap-1.5 rounded-lg border border-[#e1e0d9] bg-white px-3 text-sm text-[#52514e] hover:bg-[#f9f9f7] disabled:opacity-50"
        >
          <ArrowPathIcon className={`h-4 w-4 ${loading ? "animate-spin" : ""}`} />
          {loading ? "Đang tải" : "Tải lại"}
        </button>
      </div>
    </div>
    {generatedAt ? (
      <p className="text-xs text-[#898781]">
        Số liệu tổng hợp đến{" "}
        {new Date(generatedAt).toLocaleString("vi-VN", {
          day: "2-digit",
          month: "2-digit",
          year: "numeric",
          hour: "2-digit",
          minute: "2-digit",
        })}
      </p>
    ) : null}
  </div>
);

const Banner: React.FC<{ tone: "error" | "info"; text: string }> = ({ tone, text }) => (
  <div
    role="status"
    className={`flex items-start gap-2 rounded-xl border px-4 py-3 text-sm ${
      tone === "error"
        ? "border-red-200 bg-red-50 text-red-700"
        : "border-[#e1e0d9] bg-white text-[#52514e]"
    }`}
  >
    <ExclamationTriangleIcon className="mt-0.5 h-4 w-4 shrink-0" />
    <span className="leading-relaxed">{text}</span>
  </div>
);

// ---------------------------------------------------------------------- kpi

const Card: React.FC<{ children: React.ReactNode; className?: string }> = ({
  children,
  className = "",
}) => (
  <section
    className={`rounded-xl border border-[#e1e0d9] bg-white p-5 shadow-[0_1px_2px_rgba(16,27,30,.04)] ${className}`}
  >
    {children}
  </section>
);

const KpiRow: React.FC<{ data: VersionComparison }> = ({ data }) => {
  const published = data.versions.filter((v) => v.publishedAt);
  const latest = published[published.length - 1];
  const live = data.versions.find((v) => v.live);

  const tiles = [
    { label: "Số phiên bản", value: String(data.versions.length) },
    { label: "Bản đang phát hành", value: live?.tag ?? "—" },
    { label: "Xuất bản gần nhất", value: formatDateVi(latest?.publishedAt) },
    {
      label: "Hoàn thành cả khoá",
      value: formatMetric(live?.metrics.courseDone ?? null, "%", 1),
    },
  ];

  return (
    <div className="grid grid-cols-2 gap-4 lg:grid-cols-4">
      {tiles.map((tile) => (
        <Card key={tile.label}>
          <p className="text-xs font-medium uppercase tracking-wide text-[#898781]">
            {tile.label}
          </p>
          <p className="mt-2 text-2xl font-semibold tabular-nums text-[#0b0b0b]">
            {tile.value}
          </p>
        </Card>
      ))}
    </div>
  );
};

// ------------------------------------------------------------- dòng phiên bản

const VersionLine: React.FC<{
  versions: VersionRow[];
  selected: string[];
  baseline: string;
  onToggle: (tag: string) => void;
  onBaseline: (tag: string) => void;
  colorOf: (tag: string) => string;
}> = ({ versions, selected, baseline, onToggle, onBaseline, colorOf }) => (
  <Card>
    <div className="mb-4 flex flex-wrap items-baseline justify-between gap-2">
      <h2 className="text-base font-semibold text-[#0b0b0b]">Dòng phiên bản</h2>
      <p className="text-xs text-[#898781]">
        Tích chọn phiên bản để đưa vào bảng so sánh; bản mốc là cột gốc để tính
        chênh lệch. Tối đa {MAX_COMPARED_VERSIONS} bản, giữ tối thiểu 2 cột.
      </p>
    </div>
    <ul className="divide-y divide-[#e1e0d9]">
      {versions.map((version) => {
        const on = selected.includes(version.tag);
        const isBase = baseline === version.tag;

        return (
          <li key={version.tag} className="flex flex-wrap items-center gap-3 py-3">
            <input
              type="checkbox"
              checked={on}
              onChange={() => onToggle(version.tag)}
              aria-label={`So sánh ${version.tag}`}
              className="h-4 w-4 rounded border-[#c3c2b7]"
            />
            <span
              aria-hidden
              className="h-2.5 w-2.5 shrink-0 rounded-full"
              style={{ background: on ? colorOf(version.tag) : "#e1e0d9" }}
            />
            <span className="w-20 shrink-0 font-mono text-sm font-semibold text-[#0b0b0b]">
              {version.tag}
            </span>

            <div className="flex shrink-0 gap-1.5">
              {version.live ? (
                <span className="inline-flex items-center gap-1 rounded-full bg-emerald-50 px-2 py-0.5 text-[11px] font-medium text-emerald-700">
                  <CheckBadgeIcon className="h-3 w-3" />
                  Đang phát hành
                </span>
              ) : null}
              {!version.publishedAt ? (
                <span className="rounded-full bg-[#f9f9f7] px-2 py-0.5 text-[11px] font-medium text-[#898781]">
                  Chưa phát hành
                </span>
              ) : null}
              {isBase && on ? (
                <span className="rounded-full bg-[#eef4fb] px-2 py-0.5 text-[11px] font-medium text-[#1c5cab]">
                  Bản mốc
                </span>
              ) : null}
            </div>

            <p className="min-w-[180px] flex-1 truncate text-sm text-[#52514e]">
              {version.note || "—"}
            </p>

            <p className="shrink-0 text-xs tabular-nums text-[#898781]">
              {version.publishedAt
                ? `Phát hành từ ${formatDateVi(version.publishedAt)} · ${version.liveDays} ngày live`
                : `Đóng băng ${formatDateVi(version.createdAt)}`}
              {" · "}
              {version.lessons} bài / {version.cards} card
            </p>

            <button
              type="button"
              onClick={() => onBaseline(version.tag)}
              disabled={!on || isBase}
              className="shrink-0 rounded-lg border border-[#e1e0d9] px-2.5 py-1 text-xs text-[#52514e] hover:bg-[#f9f9f7] disabled:opacity-40"
            >
              {isBase ? "Đang là mốc" : "Đặt làm mốc"}
            </button>
          </li>
        );
      })}
    </ul>
  </Card>
);

// --------------------------------------------------------------- bảng chỉ số

const MetricTable: React.FC<{
  data: VersionComparison;
  shown: VersionRow[];
  baseRow: VersionRow;
  colorOf: (tag: string) => string;
}> = ({ data, shown, baseRow, colorOf }) => {
  let lastGroup = "";

  return (
    <Card className="overflow-hidden">
      <div className="mb-4 space-y-1">
        <h2 className="text-base font-semibold text-[#0b0b0b]">
          Bảng so sánh chỉ số
        </h2>
        <p className="text-xs leading-relaxed text-[#898781]">
          Số nhỏ dưới mỗi giá trị là chênh lệch so với bản mốc{" "}
          <span className="font-mono font-semibold">{baseRow.tag}</span>. Rê
          chuột vào ô để xem mức thấp nhất và cao nhất của chỉ số đó trong toàn
          bộ lịch sử khoá.
        </p>
      </div>

      <div className="overflow-x-auto">
        <table className="w-full min-w-[720px] border-collapse text-sm">
          <thead>
            <tr className="border-b border-[#c3c2b7]">
              <th className="py-2 pr-4 text-left font-medium text-[#898781]">
                Chỉ số
              </th>
              {shown.map((version) => (
                <th key={version.tag} className="px-4 py-2 text-right">
                  <span className="flex items-center justify-end gap-1.5">
                    <span
                      aria-hidden
                      className="h-2.5 w-2.5 rounded-full"
                      style={{ background: colorOf(version.tag) }}
                    />
                    <span className="font-mono font-semibold text-[#0b0b0b]">
                      {version.tag}
                    </span>
                  </span>
                  <span className="mt-0.5 block text-[11px] font-normal text-[#898781]">
                    {version.tag === baseRow.tag
                      ? "bản mốc"
                      : `${version.sample.courseViewers} user mở khoá`}
                  </span>
                </th>
              ))}
            </tr>
          </thead>
          <tbody>
            {data.metrics.map((metric) => {
              const groupHead = metric.group !== lastGroup ? metric.group : "";
              lastGroup = metric.group;
              const range = data.ranges?.[metric.key] ?? null;

              return (
                <React.Fragment key={metric.key}>
                  {groupHead ? (
                    <tr>
                      <td
                        colSpan={shown.length + 1}
                        className="pt-4 pb-1 text-[11px] font-semibold uppercase tracking-wide text-[#898781]"
                      >
                        {groupHead}
                      </td>
                    </tr>
                  ) : null}
                  <tr className="border-b border-[#e1e0d9] last:border-0">
                    <td className="py-3 pr-4 align-top">
                      <span className="block text-[#0b0b0b]">{metric.label}</span>
                      {metric.hint ? (
                        <span className="mt-0.5 block text-[11px] text-[#898781]">
                          {metric.hint}
                        </span>
                      ) : null}
                    </td>
                    {shown.map((version) => {
                      const raw = (version.metrics as unknown as Record<
                        string,
                        number | string | null
                      >)[metric.key];
                      const isDate = metric.type === "date";
                      const value = isDate
                        ? formatDateVi(raw as string | null)
                        : formatMetric(raw as number | null, metric.unit, metric.dec);
                      const delta = isDate
                        ? null
                        : deltaOf(
                            raw as number | null,
                            (baseRow.metrics as unknown as Record<string, number | null>)[
                              metric.key
                            ],
                            metric.polarity,
                          );
                      const isBase = version.tag === baseRow.tag;
                      const title = range
                        ? `Giá trị: ${value} · thấp nhất ${formatMetric(range.min, metric.unit, metric.dec)} · cao nhất ${formatMetric(range.max, metric.unit, metric.dec)} trong lịch sử khoá`
                        : `Giá trị: ${value}`;

                      return (
                        <td
                          key={version.tag}
                          title={title}
                          className="px-4 py-3 text-right align-top tabular-nums"
                        >
                          <span className="block font-semibold text-[#0b0b0b]">
                            {value}
                          </span>
                          {!isBase && delta ? (
                            <span
                              className={`mt-0.5 block text-[11px] ${TONE_CLASS[delta.tone]}`}
                            >
                              {formatDelta(delta, metric.unit, metric.dec)}
                            </span>
                          ) : null}
                        </td>
                      );
                    })}
                  </tr>
                </React.Fragment>
              );
            })}
          </tbody>
        </table>
      </div>
    </Card>
  );
};

// -------------------------------------------------------------------- charts

/** Gộp các đường về một mảng điểm theo bài — recharts cần một mảng chung. */
const mergeByLesson = (
  shown: VersionRow[],
  pick: (row: VersionRow) => { lessonIndex: number; pct: number }[],
): Record<string, number | null>[] => {
  const longest = Math.max(0, ...shown.map((row) => pick(row).length));

  return Array.from({ length: longest }, (_, at) => {
    const point: Record<string, number | null> = { lessonIndex: at + 1 };
    for (const row of shown) {
      const found = pick(row)[at];
      // `null` chứ không phải 0: mỗi đường DỪNG ở bài cuối của bản đó, chứ
      // không rơi xuống 0 ở những bài bản đó không có.
      point[row.tag] = found ? found.pct : null;
    }

    return point;
  });
};

const ChartTooltip: React.FC<any> = ({ active, payload, label, suffix }) => {
  if (!active || !payload?.length) return null;

  return (
    <div className="rounded-lg border border-[#e1e0d9] bg-white px-3 py-2 text-xs shadow-lg">
      <p className="mb-1 font-medium text-[#0b0b0b]">Bài {label}</p>
      {payload
        .filter((row: any) => row.value !== null && row.value !== undefined)
        .map((row: any) => (
          <p key={row.name} className="flex items-center gap-1.5 tabular-nums">
            <span
              aria-hidden
              className="h-2 w-2 rounded-full"
              style={{ background: row.color }}
            />
            <span className="font-mono text-[#52514e]">{row.name}</span>
            <span className="ml-auto font-semibold text-[#0b0b0b]">
              {row.value}
              {suffix}
            </span>
          </p>
        ))}
    </div>
  );
};

const Legend: React.FC<{ shown: VersionRow[]; colorOf: (tag: string) => string }> = ({
  shown,
  colorOf,
}) => (
  <ul className="mb-2 flex flex-wrap gap-x-4 gap-y-1">
    {shown.map((version) => (
      <li key={version.tag} className="flex items-center gap-1.5 text-xs">
        <span
          aria-hidden
          className="h-2.5 w-2.5 rounded-full"
          style={{ background: colorOf(version.tag) }}
        />
        <span className="font-mono text-[#52514e]">{version.tag}</span>
      </li>
    ))}
  </ul>
);

const RetentionChart: React.FC<{
  shown: VersionRow[];
  colorOf: (tag: string) => string;
}> = ({ shown, colorOf }) => {
  const rows = useMemo(() => mergeByLesson(shown, (row) => row.retention), [shown]);

  return (
    <Card>
      <div className="mb-3 space-y-1">
        <h2 className="text-base font-semibold text-[#0b0b0b]">
          Đường giữ chân toàn khoá
        </h2>
        <p className="text-xs leading-relaxed text-[#898781]">
          Mỗi điểm là một bài: bao nhiêu % user đã bắt đầu khoá học hoàn thành
          bài đó. Mẫu số cố định, không reset ở mỗi bài — mỗi đường dừng ở bài
          cuối của chính phiên bản đó.
        </p>
      </div>
      <Legend shown={shown} colorOf={colorOf} />
      <div className="h-[320px]">
        <ResponsiveContainer width="100%" height="100%">
          <LineChart data={rows} margin={{ top: 8, right: 56, bottom: 24, left: 0 }}>
            <CartesianGrid {...GRID_PROPS} />
            <XAxis
              {...AXIS_PROPS}
              dataKey="lessonIndex"
              label={{
                value: "Bài học trong khoá",
                position: "insideBottom",
                offset: -14,
                style: { fill: "#898781", fontSize: 12 },
              }}
            />
            <YAxis
              {...AXIS_PROPS}
              domain={[0, 100]}
              tickFormatter={(v: number) => `${v}%`}
              width={48}
            />
            <Tooltip content={<ChartTooltip suffix="%" />} />
            {shown.map((version) => (
              <Line
                key={version.tag}
                type="monotone"
                dataKey={version.tag}
                name={version.tag}
                stroke={colorOf(version.tag)}
                strokeWidth={2}
                dot={{ r: 3, strokeWidth: 0, fill: colorOf(version.tag) }}
                activeDot={{ r: 5, stroke: "#fff", strokeWidth: 2 }}
                connectNulls={false}
                isAnimationActive={false}
              />
            ))}
          </LineChart>
        </ResponsiveContainer>
      </div>
    </Card>
  );
};

const DepthChart: React.FC<{
  shown: VersionRow[];
  colorOf: (tag: string) => string;
}> = ({ shown, colorOf }) => {
  const rows = useMemo(() => mergeByLesson(shown, (row) => row.depth), [shown]);

  return (
    <Card>
      <div className="mb-3 space-y-1">
        <h2 className="text-base font-semibold text-[#0b0b0b]">
          Độ sâu theo từng bài
        </h2>
        <p className="text-xs leading-relaxed text-[#898781]">
          Trên số user đã mở bài đó, họ đọc được bao nhiêu % số card của bài.
          Đường thấp là bài bị bỏ dở giữa chừng; vòng tròn viền đỏ là bài tụt
          dưới 50%.
        </p>
      </div>
      <Legend shown={shown} colorOf={colorOf} />
      <div className="h-[320px]">
        <ResponsiveContainer width="100%" height="100%">
          <LineChart data={rows} margin={{ top: 8, right: 56, bottom: 24, left: 0 }}>
            <CartesianGrid {...GRID_PROPS} />
            <XAxis
              {...AXIS_PROPS}
              dataKey="lessonIndex"
              label={{
                value: "Bài học trong khoá",
                position: "insideBottom",
                offset: -14,
                style: { fill: "#898781", fontSize: 12 },
              }}
            />
            <YAxis
              {...AXIS_PROPS}
              domain={[0, 100]}
              tickFormatter={(v: number) => `${v}%`}
              width={48}
            />
            <Tooltip content={<ChartTooltip suffix="%" />} />
            {shown.map((version) => (
              <Line
                key={version.tag}
                type="monotone"
                dataKey={version.tag}
                name={version.tag}
                stroke={colorOf(version.tag)}
                strokeWidth={2}
                dot={{ r: 3, strokeWidth: 0, fill: colorOf(version.tag) }}
                activeDot={{ r: 5, stroke: "#fff", strokeWidth: 2 }}
                connectNulls={false}
                isAnimationActive={false}
              />
            ))}
            {/* Bài bị bỏ dở, tô thêm bằng HÌNH chứ không chỉ bằng màu. */}
            {shown.flatMap((version) =>
              (version.dropOffLessons ?? []).map((lessonIndex) => {
                const point = version.depth.find((p) => p.lessonIndex === lessonIndex);
                if (!point) return null;

                return (
                  <ReferenceDot
                    key={`${version.tag}-${lessonIndex}`}
                    x={lessonIndex}
                    y={point.pct}
                    r={6}
                    fill="none"
                    stroke="#d03b3b"
                    strokeWidth={2}
                    ifOverflow="extendDomain"
                  />
                );
              }),
            )}
          </LineChart>
        </ResponsiveContainer>
      </div>
    </Card>
  );
};

export default VersionComparisonPage;
