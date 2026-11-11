import type { MetricPolarity } from "../services/versionAnalyticsService";

export interface Delta {
  value: number;
  /** `good` tô xanh, `bad` tô đỏ, `neutral` để nguyên. */
  tone: "good" | "bad" | "neutral";
}

/**
 * Chênh lệch so với bản mốc, và màu của nó.
 *
 * Phép tính nằm ở client vì BẢN MỐC là lựa chọn của người xem — server không
 * biết người ta đang lấy bản nào làm gốc nên không thể tính trước. Nhưng
 * *hướng tốt* (`polarity`) thì server định nghĩa và gửi kèm, để "báo lỗi tăng"
 * là màu đỏ ở mọi chỗ đọc API này chứ không phải mỗi trang tự quyết.
 */
export const deltaOf = (
  value: number | null | undefined,
  baseline: number | null | undefined,
  polarity: MetricPolarity,
): Delta | null => {
  if (value === null || value === undefined) return null;
  if (baseline === null || baseline === undefined) return null;

  const diff = Math.round((value - baseline) * 10) / 10;
  // Chỉ số không có hướng (thời gian đọc) thì không bao giờ tô màu: đọc lâu
  // hơn có thể là nội dung sâu hơn, cũng có thể là viết rối — con số không tự
  // trả lời được, và tô xanh nó là trả lời hộ người xem.
  if (!polarity || diff === 0) return { value: diff, tone: "neutral" };

  return { value: diff, tone: diff * polarity > 0 ? "good" : "bad" };
};

const nf = (dec: number) =>
  new Intl.NumberFormat("vi-VN", {
    minimumFractionDigits: dec,
    maximumFractionDigits: dec,
  });

/**
 * `null` KHÔNG phải 0. "Chưa đo được" (bản chưa phát hành, chưa ai học) hiện
 * dấu gạch — đọc một phép đo còn thiếu thành 0 là đọc thành "bản này tệ".
 */
export const formatMetric = (
  value: number | string | null | undefined,
  unit: string,
  dec: number,
): string => {
  if (value === null || value === undefined || value === "") return "—";
  if (typeof value === "string") return value;

  return `${nf(dec).format(value)}${unit}`;
};

export const formatDelta = (delta: Delta | null, unit: string, dec: number): string => {
  if (!delta) return "";
  if (delta.value === 0) return `bằng bản mốc`;
  const sign = delta.value > 0 ? "+" : "−";

  return `${sign}${nf(dec).format(Math.abs(delta.value))}${unit}`;
};

export const formatDateVi = (iso: string | null | undefined): string => {
  if (!iso) return "—";
  const at = new Date(iso);
  if (Number.isNaN(+at)) return "—";

  return at.toLocaleDateString("vi-VN", {
    day: "2-digit",
    month: "2-digit",
    year: "numeric",
  });
};
