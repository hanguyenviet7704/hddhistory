// Chart tokens for the product dashboard.
//
// The series colours are the first three slots of a validated categorical
// palette, in fixed order. Two rules that are easy to break by accident:
//
// 1. **Colour follows the entity, not its rank.** SERIES.active is always blue
//    wherever active users are drawn; filtering a chart down must never repaint
//    the survivors.
// 2. **Never cycle the list to invent a 4th/5th hue.** Past three series, fold
//    the tail into "Khác" or split into two charts — a generated hue fails the
//    colour-blind separation the palette was validated for.
//
// Contrast note: AQUA sits below 3:1 on a white card, so anywhere it is used it
// ships with a visible number or a table row beside it, never colour alone.

export const SERIES = {
  active: "#2a78d6", // blue   — active users, sessions, the primary measure
  new: "#eb6834", // orange — new users, the secondary measure
  engaged: "#1baf7a", // aqua   — engaged/returning, always label-backed
} as const;

export const CHART_INK = {
  axis: "#94a3b8",
  grid: "#e2e8f0",
  text: "#475569",
  muted: "#94a3b8",
} as const;

/** Shared Recharts props so every chart on the dashboard reads as one system. */
export const AXIS_PROPS = {
  stroke: CHART_INK.axis,
  tick: { fill: CHART_INK.text, fontSize: 12 },
  tickLine: false,
  axisLine: false,
} as const;

export const GRID_PROPS = {
  stroke: CHART_INK.grid,
  strokeDasharray: "3 3",
  vertical: false,
} as const;

const numberFormatter = new Intl.NumberFormat("vi-VN");
const percentFormatter = new Intl.NumberFormat("vi-VN", {
  style: "percent",
  maximumFractionDigits: 1,
});

export const formatNumber = (value: number | null | undefined): string =>
  value === null || value === undefined ? "—" : numberFormatter.format(value);

/**
 * Null is not zero. A rate with no denominator — nobody entered the funnel, no
 * cohort is old enough for D7 — renders as an em dash so nobody reads a missing
 * measurement as a collapse to 0%.
 */
export const formatPercent = (value: number | null | undefined): string =>
  value === null || value === undefined ? "—" : percentFormatter.format(value);

export const formatDuration = (ms: number | null | undefined): string => {
  if (!ms) return "—";
  const totalSeconds = Math.round(ms / 1000);
  const minutes = Math.floor(totalSeconds / 60);
  const seconds = totalSeconds % 60;
  return minutes ? `${minutes}p ${seconds}s` : `${seconds}s`;
};

/** "2026-08-09" → "09/08" for axis ticks. */
export const formatDayTick = (date: string): string => {
  const [, month, day] = date.split("-");
  return month && day ? `${day}/${month}` : date;
};

/**
 * ISO instant → "09/08/2026", rendered in the reader's timezone.
 *
 * Parsed rather than string-sliced: the API echoes the range back as UTC
 * instants, and local midnight in Vietnam is 17:00 UTC *the day before* — a
 * `slice(0, 10)` would print every range start one day early.
 */
export const formatDate = (date: string | Date): string => {
  const parsed = typeof date === "string" ? new Date(date) : date;
  if (Number.isNaN(parsed.getTime())) return String(date);

  return parsed.toLocaleDateString("vi-VN", {
    day: "2-digit",
    month: "2-digit",
    year: "numeric",
  });
};

/** 22 → "22h". Used by the peak-hour chart and the golden-hours line. */
export const formatHour = (hour: number): string => `${hour}h`;

/**
 * Series cho các trang so sánh PHIÊN BẢN — slot 1..5 của cùng bộ palette đã
 * validate, theo thứ tự cố định.
 *
 * Không mâu thuẫn với luật "đừng vượt quá ba series" ở đầu file: luật đó nói
 * về việc TỰ SINH thêm màu. Đây là 5 slot có sẵn trong bộ, và đã chạy
 * validator ở đúng 5 slot trên nền `#fcfcfb`: lightness/chroma/CVD/ngưỡng
 * mắt thường đều PASS (cặp sát nhau tệ nhất ΔE thường 19.6).
 *
 * Hai điều kiện đi kèm, không được bỏ:
 *
 *  - **Contrast của slot 3/4/5 dưới 3:1**, nên màu KHÔNG bao giờ được là thứ
 *    duy nhất mang danh tính: mọi đồ thị dùng bộ này phải có legend, nhãn
 *    trực tiếp ở cuối đường, và một bảng số bên cạnh.
 *  - **Màu theo phiên bản, không theo thứ hạng.** Chỉ số slot phải lấy từ vị
 *    trí của bản trong TOÀN BỘ danh sách, không phải trong danh sách đang tích
 *    chọn — nếu không thì bỏ tích một bản sẽ sơn lại màu của những bản còn lại.
 */
export const VERSION_SERIES = [
  "#2a78d6",
  "#eb6834",
  "#1baf7a",
  "#eda100",
  "#e87ba4",
] as const;

/** Bao nhiêu bản so được một lúc — bằng số slot, không cycle để có slot thứ 6. */
export const MAX_COMPARED_VERSIONS = VERSION_SERIES.length;
