export const formatDateTime = (value?: string | Date | null) => {
  if (!value) return "-";
  const date = new Date(value);
  if (Number.isNaN(date.getTime())) return "-";
  return date.toLocaleString("vi-VN", { hour12: false });
};

export const formatClock = (value?: string | Date | null) => {
  if (!value) return "-";
  const date = new Date(value);
  if (Number.isNaN(date.getTime())) return "-";
  return date.toLocaleTimeString("vi-VN", { hour12: false });
};

export const formatDayLabel = (value?: string | Date | null) => {
  if (!value) return "-";
  const date = new Date(value);
  if (Number.isNaN(date.getTime())) return "-";
  return date.toLocaleDateString("vi-VN");
};

/** 0 -> "0s", 65_000 -> "1m 5s", 3_725_000 -> "1h 2m". */
export const formatDuration = (ms?: number) => {
  if (!ms || ms < 0) return "0s";
  const totalSeconds = Math.round(ms / 1000);
  const hours = Math.floor(totalSeconds / 3600);
  const minutes = Math.floor((totalSeconds % 3600) / 60);
  const seconds = totalSeconds % 60;

  if (hours > 0) return `${hours}h ${minutes}m`;
  if (minutes > 0) return `${minutes}m ${seconds}s`;
  return `${seconds}s`;
};

/** ISO string for `daysAgo` days back at 00:00 local, used by the range filter. */
export const isoDaysAgo = (daysAgo: number) => {
  const date = new Date();
  date.setDate(date.getDate() - daysAgo);
  date.setHours(0, 0, 0, 0);
  return date.toISOString();
};

const PARAM_SUMMARY_KEYS = [
  "course_name",
  "lesson_name",
  "keypoint_name",
  "skill_name",
  "screen_class",
  "source",
];

/** The few params that make an event readable at a glance in the timeline. */
export const summarizeParams = (params?: Record<string, any>) => {
  if (!params) return "";
  return PARAM_SUMMARY_KEYS.filter(
    (key) => params[key] !== undefined && params[key] !== null && params[key] !== "",
  )
    .map((key) => `${key}: ${params[key]}`)
    .join(" · ");
};
