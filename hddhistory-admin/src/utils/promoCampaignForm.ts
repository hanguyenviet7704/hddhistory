/**
 * Shared bits for editing one "promo campaign" row — a Home banner slide or a
 * Home popup item. Both are the same shape server-side (name, locales,
 * priority, startAt/endAt, and an index-aligned impressions/clicks/ctr stats
 * row), so the form plumbing that is not entity-specific (image, link,
 * countries) lives here once instead of twice.
 */
import { LangCode } from "../types/enum/common.enum";

/** Language allow-list options — the five locales the app ships. */
export const LOCALE_OPTIONS: { code: string; label: string }[] = [
  { code: LangCode.VI, label: "Tiếng Việt" },
  { code: LangCode.EN, label: "English" },
  { code: LangCode.ZH, label: "中文" },
  { code: LangCode.JA, label: "日本語" },
  { code: LangCode.KO, label: "한국어" },
];

export function localeLabel(code: string): string {
  return LOCALE_OPTIONS.find((l) => l.code === code)?.label ?? code;
}

/**
 * Read-only performance for one campaign row, aligned BY INDEX with the
 * configured slides/popups (see `slideStats` / `popupStats` on the config
 * response). `campaignKey` is a content hash of image + link, computed
 * server-side — changing either field forks a new campaign and its stats
 * restart at zero.
 */
export interface PromoCampaignStats {
  campaignKey: string;
  impressions: number;
  clicks: number;
  /** clicks / impressions as a ratio (0 when nothing was shown yet) — render with `formatCtr`. */
  ctr: number;
}

/** `0.034` -> `"3.4%"`. */
export const formatCtr = (ctr: number): string => `${(ctr * 100).toFixed(1)}%`;

// `datetime-local` inputs work in unzoned "YYYY-MM-DDTHH:mm" strings; the API
// expects/returns full ISO 8601. Convert only at the edges.
export const toInputDateTime = (value?: string | null): string => {
  if (!value) return "";
  const date = new Date(value);
  if (Number.isNaN(date.getTime())) return "";
  const pad = (n: number) => String(n).padStart(2, "0");
  return `${date.getFullYear()}-${pad(date.getMonth() + 1)}-${pad(
    date.getDate(),
  )}T${pad(date.getHours())}:${pad(date.getMinutes())}`;
};

/**
 * Empty input -> `null` (open bound), never `undefined` — clearing a date on
 * an existing campaign must overwrite whatever is stored, not be dropped as a
 * no-op.
 */
export const fromInputDateTime = (value: string): string | null => {
  if (!value) return null;
  const date = new Date(value);
  return Number.isNaN(date.getTime()) ? null : date.toISOString();
};
