import {
  FeedbackEntry,
  FeedbackType,
  IncompleteFeedbackReason,
} from "../../types/enum/feedback.enum";

/** Reader-facing labels for the five abandon reasons the app can send. */
export const REASON_LABELS: Record<IncompleteFeedbackReason, string> = {
  [IncompleteFeedbackReason.HARD_TO_UNDERSTAND]: "Khó hiểu",
  [IncompleteFeedbackReason.NOT_ENGAGING]: "Không cuốn",
  [IncompleteFeedbackReason.POOR_VISUALS]: "Hình ảnh chưa tốt",
  [IncompleteFeedbackReason.HARD_QUESTIONS]: "Câu hỏi khó",
  [IncompleteFeedbackReason.NEEDS_MORE_EXAMPLES]: "Cần thêm ví dụ",
};

/**
 * An unknown reason is shown raw rather than dropped: the app can ship a new
 * enum value before this table learns about it, and a silently missing bar
 * would read as "nobody picked that".
 */
export const reasonLabel = (reason: string) =>
  REASON_LABELS[reason as IncompleteFeedbackReason] ?? reason;

export const ENTRY_LABELS: Record<FeedbackEntry, string> = {
  [FeedbackEntry.KEYPOINT]: "Keypoint",
  [FeedbackEntry.ROLEPLAY]: "Roleplay",
};

export const TYPE_LABELS: Record<FeedbackType, string> = {
  [FeedbackType.COMPLETE]: "Hoàn thành",
  [FeedbackType.INCOMPLETE]: "Bỏ dở",
};

/** Bar colours for the reason chart, cycled by rank. */
export const REASON_COLORS = [
  "bg-red-600",
  "bg-orange-500",
  "bg-amber-500",
  "bg-sky-600",
  "bg-bronze-600",
];

export const RATING_COLORS = [
  "bg-red-600",
  "bg-orange-600",
  "bg-amber-500",
  "bg-emerald-600",
  "bg-green-700",
];

export const formatNumber = (value?: number | null) =>
  value === null || value === undefined ? "-" : value.toLocaleString("vi-VN");

export const formatDateTime = (value?: string) => {
  if (!value) return "-";
  const date = new Date(value);
  if (Number.isNaN(date.getTime())) return "-";
  return date.toLocaleString("vi-VN", { hour12: false });
};

/** yyyy-mm-dd for the date inputs and the API, in LOCAL time (not UTC). */
export const toInputDate = (date: Date) => {
  const offset = date.getTimezoneOffset();
  return new Date(date.getTime() - offset * 60_000).toISOString().slice(0, 10);
};

export const presetRange = (days: number) => {
  const end = new Date();
  const start = new Date();
  start.setDate(start.getDate() - (days - 1));
  return { startDate: toInputDate(start), endDate: toInputDate(end) };
};

/** Hands the workbook to the browser as a download. */
export const downloadXlsx = (blob: Blob, fileName: string) => {
  const url = URL.createObjectURL(blob);
  const link = document.createElement("a");
  link.href = url;
  link.download = fileName;
  link.click();
  URL.revokeObjectURL(url);
};
