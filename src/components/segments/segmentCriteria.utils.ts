/**
 * Shared vocabulary for the segment criteria builder and its list-row summary:
 * option lists with Vietnamese labels, and a chip-summary formatter. Kept out
 * of the components so the same labels are used everywhere a criterion shows
 * up (form checkboxes, list chips).
 */
import {
  SegmentCriteria,
  SegmentDeviceType,
  SegmentUserType,
} from "../../types/interface/segment.interface";

export const DEVICE_TYPE_OPTIONS: { value: SegmentDeviceType; label: string }[] = [
  { value: "ios", label: "iOS" },
  { value: "android", label: "Android" },
];

export const deviceTypeLabel = (value: string): string =>
  DEVICE_TYPE_OPTIONS.find((o) => o.value === value)?.label ?? value;

export const USER_TYPE_OPTIONS: { value: SegmentUserType; label: string }[] = [
  { value: "pro_lifetime", label: "Pro trọn đời (is_pro_lifetime)" },
  { value: "pro_subscription", label: "Pro có hạn (is_pro_subscription)" },
  { value: "free_logged_in", label: "Free đã đăng nhập (is_free_logged_in)" },
  { value: "free_guest", label: "Free chưa đăng nhập (is_free_guest)" },
];

export const userTypeLabel = (value: string): string =>
  USER_TYPE_OPTIONS.find((o) => o.value === value)?.label ?? value;

/** Short label, dropped the "(is_x)" suffix — for the compact list chip. */
const userTypeShortLabel = (value: string): string =>
  userTypeLabel(value).split(" (")[0];

const shortDate = (iso?: string | null): string | null => {
  if (!iso) return null;
  const date = new Date(iso);
  return Number.isNaN(date.getTime()) ? null : date.toLocaleDateString("vi-VN");
};

/**
 * Concise, human-readable chip labels describing a segment's criteria — for
 * the list table. Every field that is unset contributes nothing; an empty
 * result means "matches everyone" and the caller should show that instead.
 */
export function summarizeCriteria(criteria?: SegmentCriteria | null): string[] {
  if (!criteria) return [];
  const chips: string[] = [];

  const firstFrom = shortDate(criteria.firstSessionFrom);
  const firstTo = shortDate(criteria.firstSessionTo);
  if (firstFrom || firstTo) {
    chips.push(`Lần đầu ${firstFrom ?? "…"} → ${firstTo ?? "…"}`);
  }

  const lastFrom = shortDate(criteria.lastSessionFrom);
  const lastTo = shortDate(criteria.lastSessionTo);
  if (lastFrom || lastTo) {
    chips.push(`Gần nhất ${lastFrom ?? "…"} → ${lastTo ?? "…"}`);
  }

  if (criteria.languages?.length) {
    chips.push(`Ngôn ngữ: ${criteria.languages.join(", ")}`);
  }

  if (criteria.countries?.length) {
    chips.push(`Quốc gia: ${criteria.countries.join(", ")}`);
  }

  if (criteria.deviceTypes?.length) {
    chips.push(`Thiết bị: ${criteria.deviceTypes.map(deviceTypeLabel).join(", ")}`);
  }

  if (criteria.lifecycleFrom != null || criteria.lifecycleTo != null) {
    chips.push(`D${criteria.lifecycleFrom ?? 0}–D${criteria.lifecycleTo ?? "∞"}`);
  }

  if (criteria.userIds?.length) {
    chips.push(`${criteria.userIds.length} user cụ thể`);
  }

  if (criteria.userGoals?.length) {
    chips.push(`Mục tiêu #${criteria.userGoals.join(", ")}`);
  }

  if (criteria.topicIds?.length) {
    chips.push(`Chủ đề #${criteria.topicIds.join(", ")}`);
  }

  if (criteria.userTypes?.length) {
    chips.push(criteria.userTypes.map(userTypeShortLabel).join(", "));
  }

  return chips;
}
