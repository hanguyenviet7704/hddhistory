const ONE_DAY_MS = 24 * 60 * 60 * 1000;
const ONE_MINUTE_MS = 60 * 1000;

export const STREAK_WEEK_DAYS = 7;

// Real-world timezone bounds: UTC-12 (Baker Island) .. UTC+14 (Kiritimati).
const MIN_TIMEZONE_OFFSET_MINUTES = -720;
const MAX_TIMEZONE_OFFSET_MINUTES = 840;

export function normalizeWeekStudy(weekStudy?: boolean[]) {
  const normalized = Array.from({ length: STREAK_WEEK_DAYS }, () => false);
  if (!Array.isArray(weekStudy)) {
    return normalized;
  }

  for (let index = 0; index < STREAK_WEEK_DAYS; index += 1) {
    normalized[index] = Boolean(weekStudy[index]);
  }

  return normalized;
}

/**
 * Minutes the client's local time is ahead of UTC, from the `x-timezone-offset`
 * header (Vietnam = 420).
 *
 * TV: Header thiếu hoặc rác thì coi như 0 (UTC) — đúng hành vi trước khi có
 * header này. Không bao giờ throw: một header sai không được phép làm sập
 * endpoint streak.
 */
export function normalizeTimezoneOffset(value?: unknown) {
  const parsed = Number(Array.isArray(value) ? value[0] : value);
  if (!Number.isFinite(parsed)) {
    return 0;
  }

  const minutes = Math.trunc(parsed);
  if (
    minutes < MIN_TIMEZONE_OFFSET_MINUTES ||
    minutes > MAX_TIMEZONE_OFFSET_MINUTES
  ) {
    return 0;
  }

  return minutes;
}

/**
 * Strips the time off a date that is ALREADY a calendar day in the user's
 * timezone — the shape every date stored on the streak record has.
 *
 * Deliberately reads the UTC components: these dates are "floating" days
 * (midnight-UTC standing in for a local calendar date), so interpreting them
 * through the server's own timezone is what made the streak silently depend on
 * the container's TZ.
 */
export function toFloatingDay(date: Date) {
  return new Date(
    Date.UTC(date.getUTCFullYear(), date.getUTCMonth(), date.getUTCDate()),
  );
}

// Returns all "today context" values in one function to avoid many tiny helpers:
// - todayStart: today at 00:00
// - weekStartDate: Monday at 00:00
// - weekDayIndex: Mon=0 ... Sun=6
//
// All three are in the CLIENT's timezone, expressed as floating days (see
// [toFloatingDay]). Previously these came from `setHours`/`getDay`, i.e. the
// server container's clock — which is UTC, so a lesson finished at 01:00 in
// Vietnam was filed under the previous day.
export function getWeekContext(date: Date, offsetMinutes = 0) {
  const shifted = new Date(date.getTime() + offsetMinutes * ONE_MINUTE_MS);

  const jsDay = shifted.getUTCDay(); // Sun=0 ... Sat=6
  const weekDayIndex = jsDay === 0 ? 6 : jsDay - 1; // Mon=0 ... Sun=6

  const todayStart = toFloatingDay(shifted);
  // Date.UTC normalizes a negative day-of-month across month and year ends.
  const weekStartDate = new Date(
    Date.UTC(
      shifted.getUTCFullYear(),
      shifted.getUTCMonth(),
      shifted.getUTCDate() - weekDayIndex,
    ),
  );

  return {
    todayStart,
    weekStartDate,
    weekDayIndex,
  };
}

export function getDayDiff(laterDate: Date, earlierDate: Date) {
  const later = toFloatingDay(laterDate);
  const earlier = toFloatingDay(earlierDate);

  // Both operands are midnight UTC, so the gap is an exact multiple of a day;
  // round rather than floor so no future rewrite can lose a day to drift.
  return Math.round((later.getTime() - earlier.getTime()) / ONE_DAY_MS);
}

export function inferLastCompletedDate(weekStartDate: Date, weekStudy: boolean[]) {
  const normalizedWeekStudy = normalizeWeekStudy(weekStudy);
  let lastCompletedIndex = -1;

  for (let index = STREAK_WEEK_DAYS - 1; index >= 0; index -= 1) {
    if (normalizedWeekStudy[index]) {
      lastCompletedIndex = index;
      break;
    }
  }

  if (lastCompletedIndex < 0) {
    return null;
  }

  const weekStart = toFloatingDay(weekStartDate);

  return new Date(
    Date.UTC(
      weekStart.getUTCFullYear(),
      weekStart.getUTCMonth(),
      weekStart.getUTCDate() + lastCompletedIndex,
    ),
  );
}
