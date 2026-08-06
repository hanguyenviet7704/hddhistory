import React from "react";

import { HabitCheckinMethod } from "../../types/enum/habit.enum";

/**
 * Journal mood is a 3-level scale stored 1-based (see the API's
 * habit-checkin.schema.ts for why 0 is never used).
 *
 * NOTE: these labels are the admin's own wording. The app's real labels are
 * slang l10n strings across 5 locales and are not mirrored here on purpose —
 * duplicating them would just give us a second copy to drift. All the admin
 * needs is a readable rendering of 1/2/3.
 */
export const MOOD_LABELS: Record<number, { emoji: string; label: string }> = {
  1: { emoji: "😕", label: "Tough" },
  2: { emoji: "🙂", label: "Okay" },
  3: { emoji: "😄", label: "Great" },
};

export const renderMood = (mood?: number) => {
  if (mood === undefined || mood === null) return "-";
  const entry = MOOD_LABELS[mood];
  if (!entry) return String(mood);
  return `${entry.emoji} ${entry.label}`;
};

/**
 * Rows written before practice shipped carry no `method`. They came from the
 * quick 7-day-strip toggle, so they read as Tap — not as "unknown".
 */
export const METHOD_LABELS: Record<HabitCheckinMethod, string> = {
  [HabitCheckinMethod.TAP]: "Tap",
  [HabitCheckinMethod.JOURNAL]: "Journal",
  [HabitCheckinMethod.EXERCISE]: "Quiz",
  [HabitCheckinMethod.VIDEO]: "Video",
  [HabitCheckinMethod.ROLEPLAY]: "Roleplay",
};

export const METHOD_PILL_CLASSES: Record<HabitCheckinMethod, string> = {
  [HabitCheckinMethod.TAP]: "bg-gray-100 text-gray-600",
  [HabitCheckinMethod.JOURNAL]: "bg-indigo-100 text-indigo-700",
  [HabitCheckinMethod.EXERCISE]: "bg-emerald-100 text-emerald-700",
  [HabitCheckinMethod.VIDEO]: "bg-sky-100 text-sky-700",
  [HabitCheckinMethod.ROLEPLAY]: "bg-amber-100 text-amber-700",
};

export const methodOf = (method?: HabitCheckinMethod): HabitCheckinMethod =>
  method ?? HabitCheckinMethod.TAP;

export const MethodPill: React.FC<{ method?: HabitCheckinMethod }> = ({
  method,
}) => {
  const resolved = methodOf(method);
  return (
    <span
      className={`inline-block rounded-full px-2 py-0.5 text-xs font-semibold ${METHOD_PILL_CLASSES[resolved]}`}
    >
      {METHOD_LABELS[resolved]}
    </span>
  );
};

export const formatDateTime = (value?: string | Date | null) => {
  if (!value) return "-";
  const date = new Date(value);
  if (Number.isNaN(date.getTime())) return "-";
  return date.toLocaleString("vi-VN", { hour12: false });
};

export const formatDateOnly = (value?: string | Date | null) => {
  if (!value) return "-";
  const date = new Date(value);
  if (Number.isNaN(date.getTime())) return "-";
  return date.toLocaleDateString("vi-VN");
};
