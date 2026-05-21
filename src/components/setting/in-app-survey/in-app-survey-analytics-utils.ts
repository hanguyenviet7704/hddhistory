import { LangCode } from "../../../types/enum/common.enum";
import { InAppSurveyExportRow } from "../../../types/interface/in-app-survey.interface";
import { getTranslationValue } from "../../../utils/translation";

export type SurveyTab = "byResponse" | "byUser";
export type DatePreset = "30" | "60" | "custom";

export const buildDateRangeParams = (
  preset: DatePreset,
  customStart: string,
  customEnd: string,
) => {
  const isCustom = preset === "custom";
  const end = isCustom ? parseEndDate(customEnd) : new Date();
  const rangeDays = isCustom ? 30 : Number(preset);
  const start =
    isCustom && customStart
      ? parseStartDate(customStart, end, rangeDays)
      : new Date(end.getTime() - rangeDays * 24 * 60 * 60 * 1000);

  return {
    startDate: start.toISOString(),
    endDate: end.toISOString(),
  };
};

const parseStartDate = (dateValue: string, end: Date, fallbackDays: number) => {
  const date = startOfDay(dateValue);
  return isValidDate(date)
    ? date
    : new Date(end.getTime() - fallbackDays * 24 * 60 * 60 * 1000);
};

const parseEndDate = (dateValue: string) => {
  if (!dateValue) return new Date();
  const date = endOfDay(dateValue);
  return isValidDate(date) ? date : new Date();
};

const startOfDay = (dateValue: string) => {
  const date = new Date(dateValue);
  date.setHours(0, 0, 0, 0);
  return date;
};

const endOfDay = (dateValue: string) => {
  const date = new Date(dateValue);
  date.setHours(23, 59, 59, 999);
  return date;
};

const isValidDate = (date: Date) => !Number.isNaN(date.getTime());

export const formatNumber = (value?: number) =>
  new Intl.NumberFormat("en-US").format(value || 0);

export const formatDateTime = (value?: string) => {
  if (!value) return "-";
  const date = new Date(value);
  if (Number.isNaN(date.getTime())) return "-";
  return date.toLocaleString("vi-VN", { hour12: false });
};

export const getBranchLabel = (
  score?: number,
  name?: string,
  fallback = "Branch",
) => name || `${fallback} ${score || ""}`.trim();

export const stripHtmlText = (value?: string) => {
  if (!value) return "";

  return value
    .replace(/<br\s*\/?>/gi, " ")
    .replace(/<\/(p|div|h[1-6]|li)>/gi, " ")
    .replace(/<[^>]+>/g, "")
    .replace(/&nbsp;/g, " ")
    .replace(/&amp;/g, "&")
    .replace(/&lt;/g, "<")
    .replace(/&gt;/g, ">")
    .replace(/&quot;/g, '"')
    .replace(/&#39;/g, "'")
    .replace(/\s+/g, " ")
    .trim();
};

export const getPlainTranslationValue = (value: any, lang: LangCode) =>
  stripHtmlText(getTranslationValue(value, lang));

export const getQuestionText = (value: any, lang: LangCode) =>
  getPlainTranslationValue(value?.question, lang) || "-";

export const downloadSurveyCsv = (
  rows: InAppSurveyExportRow[],
  fileName = "in-app-survey-responses.csv",
) => {
  const headers = [
    "user_id",
    "user_name",
    "user_email",
    "emoji_level",
    "emoji_name",
    "selected_options",
    "feedback",
    "submitted_at",
  ];
  const csv = [
    headers.join(","),
    ...rows.map((row) =>
      headers.map((header) => escapeCsv((row as any)[header])).join(","),
    ),
  ].join("\n");
  const blob = new Blob([csv], { type: "text/csv;charset=utf-8;" });
  const url = URL.createObjectURL(blob);
  const link = document.createElement("a");
  link.href = url;
  link.download = fileName;
  link.click();
  URL.revokeObjectURL(url);
};

const escapeCsv = (value: unknown) => {
  const text = String(value ?? "");
  return `"${text.replace(/"/g, '""')}"`;
};
