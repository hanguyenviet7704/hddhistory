const DAYS_PER_WEEK = 7;
const MS_PER_DAY = 24 * 60 * 60 * 1000;
const MS_PER_MINUTE = 60_000;

/** The seven local days of one week, and the windows that address them. */
export interface WeekBounds {
  /** Local Monday 00:00 as the instant it is in UTC. */
  weekStart: Date;
  /** Local Monday 00:00 of the FOLLOWING week — an exclusive upper bound. */
  weekEnd: Date;
  /** `YYYY-MM-DD` for each of the seven local days, Monday first. */
  dates: string[];
  /**
   * The same seven days as `habit_checkins` files them: date-only at UTC
   * midnight, no offset applied.
   *
   * Keypoint submissions are real timestamps and need the shifted window
   * above; habit check-ins are normalised to a bare calendar date and are
   * matched against these instead. Using one rule for both is how a habit lands
   * on the wrong day (see `StudyJournalHabitRepository`).
   */
  dateOnlyFrom: Date;
  dateOnlyTo: Date;
}

/** Local midnight of (year, month, day) as the instant it is in UTC. */
export function localMidnightToUtc(
  year: number,
  month: number,
  day: number,
  tzOffset: number,
): Date {
  return new Date(Date.UTC(year, month - 1, day) - tzOffset * MS_PER_MINUTE);
}

/** `YYYY-MM-DD` of an instant, read in the learner's timezone. */
export function formatLocalDate(instant: Date, tzOffset: number): string {
  const local = new Date(instant.getTime() + tzOffset * MS_PER_MINUTE);

  return [
    local.getUTCFullYear(),
    pad(local.getUTCMonth() + 1),
    pad(local.getUTCDate()),
  ].join('-');
}

/**
 * A Monday-to-Sunday week in the learner's timezone.
 *
 * `weeksAgo` counts back from the week in progress: 1 is the week that just
 * finished — what a recap is normally cut from — and 0 is the current,
 * unfinished one, which only the preview path asks for.
 *
 * Monday-based because the product is: the recap is offered on Monday for the
 * seven days before it. `getUTCDay` is Sunday-based, hence the `+ 6) % 7` shift
 * — without it every Sunday would be filed as the start of a week rather than
 * the end of one.
 *
 * Called with the local wall-clock shifted into UTC, so all the reads below are
 * `getUTC*` on purpose: the host's own timezone never enters the calculation.
 */
export function weekBounds(
  now: Date,
  tzOffset: number,
  weeksAgo = 1,
): WeekBounds {
  const local = new Date(now.getTime() + tzOffset * MS_PER_MINUTE);
  const mondayIndex = (local.getUTCDay() + 6) % DAYS_PER_WEEK;

  const lastMonday = new Date(
    Date.UTC(local.getUTCFullYear(), local.getUTCMonth(), local.getUTCDate()) -
      (mondayIndex + weeksAgo * DAYS_PER_WEEK) * MS_PER_DAY,
  );

  const dates: string[] = [];
  for (let offset = 0; offset < DAYS_PER_WEEK; offset++) {
    const day = new Date(lastMonday.getTime() + offset * MS_PER_DAY);
    dates.push(
      [
        day.getUTCFullYear(),
        pad(day.getUTCMonth() + 1),
        pad(day.getUTCDate()),
      ].join('-'),
    );
  }

  const dateOnlyTo = new Date(lastMonday.getTime() + DAYS_PER_WEEK * MS_PER_DAY);

  return {
    weekStart: new Date(lastMonday.getTime() - tzOffset * MS_PER_MINUTE),
    weekEnd: new Date(dateOnlyTo.getTime() - tzOffset * MS_PER_MINUTE),
    dates,
    dateOnlyFrom: lastMonday,
    dateOnlyTo,
  };
}

/**
 * The longest unbroken run of `true`, which is what the poster's "CHUỖI" stamp
 * counts.
 *
 * Deliberately scoped to the week rather than reading the learner's global
 * streak: a week that ends on a rest day zeroes the global streak, and a `0`
 * printed directly above a calendar row showing six studied days reads as a
 * bug in one of the two.
 */
export function longestRun(flags: boolean[]): number {
  let best = 0;
  let current = 0;

  for (const flag of flags) {
    current = flag ? current + 1 : 0;
    if (current > best) best = current;
  }

  return best;
}

function pad(value: number): string {
  return String(value).padStart(2, '0');
}

/** The week that just finished — what a stored recap is cut from. */
export function previousWeekBounds(now: Date, tzOffset: number): WeekBounds {
  return weekBounds(now, tzOffset, 1);
}
