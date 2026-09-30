/**
 * Monday 00:00 UTC of the week containing `now`.
 *
 * One fixed boundary for everyone rather than per-timezone weeks: the only
 * things it gates are a topic's "N bài tuần này" counter and the cron that
 * zeroes it, and those have to agree with each other, not with a reader's
 * calendar.
 */
export function startOfWeekUtc(now: Date): Date {
  const date = new Date(
    Date.UTC(now.getUTCFullYear(), now.getUTCMonth(), now.getUTCDate()),
  );
  // getUTCDay: Sunday is 0, so shift it to the end of the week.
  const weekday = date.getUTCDay() === 0 ? 7 : date.getUTCDay();
  date.setUTCDate(date.getUTCDate() - (weekday - 1));
  return date;
}
