const ONE_DAY_MS = 24 * 60 * 60 * 1000;
export const WEEK_GRID_DAYS = 7;

// Date-only fields are stored as UTC midnight of a calendar day. WHICH calendar
// day is the user's, not the server's — see [localDateOnly]; this function only
// truncates a date it is given.
export function normalizeDateOnly(date: Date | string = new Date()): Date {
  const d = new Date(date);
  return new Date(Date.UTC(d.getUTCFullYear(), d.getUTCMonth(), d.getUTCDate()));
}

/**
 * Today in [timezone], as the UTC-midnight value this module stores date-only
 * fields against.
 *
 * The server's own UTC date is NOT the reader's day: for UTC+7, every moment
 * between local midnight and 07:00 still carries the previous UTC date. A habit
 * ticked at 01:00 was therefore filed under yesterday — the 21:00 reminder went
 * on insisting it was unchecked, and the streak credited the wrong day. Resolves
 * the timezone-basis question the old `[ASSUMPTION]` note left open.
 *
 * An absent or unrecognised zone falls back to the server's UTC date, which is
 * exactly the previous behaviour.
 *
 * Prefer [localDateOnlyFromOffsetMinutes] when a request is in hand: the
 * `x-timezone-offset` header comes from the device actually calling, while the
 * stored zone can be stale. This one exists for the accounts whose app build
 * does not send that header yet.
 */
export function localDateOnlyFromOffsetMinutes(
  offsetMinutes: number,
  now: Date = new Date(),
): Date {
  return normalizeDateOnly(new Date(now.getTime() + offsetMinutes * 60_000));
}

export function localDateOnly(
  timezone?: string,
  now: Date = new Date(),
): Date {
  if (!timezone) return normalizeDateOnly(now);
  try {
    // en-CA formats as YYYY-MM-DD — same trick the notification dispatcher uses
    // to read a zone's local date.
    const localDate = new Intl.DateTimeFormat('en-CA', {
      timeZone: timezone,
      year: 'numeric',
      month: '2-digit',
      day: '2-digit',
    }).format(now);
    return new Date(`${localDate}T00:00:00.000Z`);
  } catch {
    return normalizeDateOnly(now);
  }
}

export function getDayDiff(laterDate: Date, earlierDate: Date): number {
  const later = normalizeDateOnly(laterDate);
  const earlier = normalizeDateOnly(earlierDate);
  return Math.round((later.getTime() - earlier.getTime()) / ONE_DAY_MS);
}

// Monday of the UTC week containing `date` (Mon=start, matches
// user-streak.helper.getWeekContext for consistency across the app).
export function getWeekStartDate(date: Date): Date {
  const dayOnly = normalizeDateOnly(date);
  const jsDay = dayOnly.getUTCDay(); // Sun=0 ... Sat=6
  const weekDayIndex = jsDay === 0 ? 6 : jsDay - 1; // Mon=0 ... Sun=6
  const weekStart = new Date(dayOnly);
  weekStart.setUTCDate(dayOnly.getUTCDate() - weekDayIndex);
  return weekStart;
}

// Recomputes currentStreak/totalCheckIns/lastCheckInDate from the FULL set of
// `done` checkin dates, rather than an incremental delta — makes the result
// correct even if a check-in is re-posted for an already-recorded day
// (idempotent) or a day is toggled from done -> not-done after the fact.
// [today] must be the READER's day (see [localDateOnly]); it defaults to the
// server's UTC date only for callers that have no user in hand.
export function computeStreakFromDoneDates(
  doneDates: Date[],
  today: Date = normalizeDateOnly(new Date()),
): {
  currentStreak: number;
  lastCheckInDate: Date | null;
} {
  if (!doneDates.length) {
    return { currentStreak: 0, lastCheckInDate: null };
  }

  const sortedDesc = [...doneDates]
    .map(normalizeDateOnly)
    .sort((a, b) => b.getTime() - a.getTime());

  const lastCheckInDate = sortedDesc[0];

  // Streak only counts if the most recent done day is today or yesterday —
  // a gap of 2+ days from "now" means the streak is already broken even if
  // no new check-in has arrived to record that yet.
  if (getDayDiff(today, lastCheckInDate) >= 2) {
    return { currentStreak: 0, lastCheckInDate };
  }

  let streak = 1;
  for (let i = 1; i < sortedDesc.length; i += 1) {
    const gap = getDayDiff(sortedDesc[i - 1], sortedDesc[i]);
    if (gap === 1) {
      streak += 1;
    } else if (gap === 0) {
      // duplicate date guard — shouldn't happen given the unique index.
      continue;
    } else {
      break;
    }
  }

  return { currentStreak: streak, lastCheckInDate };
}

// 7-box weekly grid (Mon..Sun) of done flags for the Habit tab's week view.
export function buildWeekGrid(weekStartDate: Date, doneDates: Date[]): boolean[] {
  const doneSet = new Set(doneDates.map(d => normalizeDateOnly(d).getTime()));
  const grid = new Array(WEEK_GRID_DAYS).fill(false);
  for (let i = 0; i < WEEK_GRID_DAYS; i += 1) {
    const day = new Date(weekStartDate);
    day.setUTCDate(weekStartDate.getUTCDate() + i);
    grid[i] = doneSet.has(day.getTime());
  }
  return grid;
}
