import { EXPLORE_WEEK_TIMEZONE } from './explore.constant';

/**
 * Midnight on the most recent Monday, in [timezone], as a UTC instant.
 *
 * The window runs Monday through Sunday — the whole week, not Monday to
 * Saturday: a reader who only studies at the weekend has to land in some week,
 * and leaving Sunday out of every window would drop them from the ranking
 * entirely.
 *
 * Uses the zone's offset as it stands NOW for a boundary up to seven days back,
 * which is exact for Asia/Ho_Chi_Minh because Vietnam keeps no DST. A zone that
 * shifted inside the window would put the boundary an hour out — harmless for a
 * popularity ranking, but worth knowing before reusing this for billing.
 */
export function startOfCurrentWeek(
  now: Date = new Date(),
  timezone: string = EXPLORE_WEEK_TIMEZONE,
): Date {
  // en-CA renders as YYYY-MM-DD, the same trick the notification dispatcher
  // uses to read a zone's local calendar date without a date library.
  const parts = new Intl.DateTimeFormat('en-CA', {
    timeZone: timezone,
    year: 'numeric',
    month: '2-digit',
    day: '2-digit',
    hour: '2-digit',
    minute: '2-digit',
    second: '2-digit',
    hour12: false,
  }).formatToParts(now);

  const get = (type: string) =>
    Number(parts.find(p => p.type === type)?.value ?? '0');
  // Intl renders midnight as hour 24 in some ICU versions; 24 and 0 are the
  // same instant, and leaving it at 24 would push the offset a day out.
  const hour = get('hour') % 24;

  // The zone's wall clock read as if it were UTC, minus the real instant, is
  // the zone's current offset.
  const wallClockAsUtc = Date.UTC(
    get('year'),
    get('month') - 1,
    get('day'),
    hour,
    get('minute'),
    get('second'),
  );
  const offsetMs = wallClockAsUtc - Math.floor(now.getTime() / 1000) * 1000;

  const localMidnightAsUtc = Date.UTC(
    get('year'),
    get('month') - 1,
    get('day'),
  );
  // Weekday of the local date, Monday = 0.
  const weekday = (new Date(localMidnightAsUtc).getUTCDay() + 6) % 7;

  return new Date(localMidnightAsUtc - weekday * 86_400_000 - offsetMs);
}

/**
 * Fisher-Yates, plain `Math.random`.
 *
 * Nothing here needs to be reproducible: the ORDER a reader sees is shuffled
 * again on the client every time they open the tab, so a seed the two sides
 * would have to agree on bought nothing and cost an extra query parameter.
 */
export function shuffle<T>(items: T[]): T[] {
  const out = [...items];
  for (let i = out.length - 1; i > 0; i--) {
    const j = Math.floor(Math.random() * (i + 1));
    [out[i], out[j]] = [out[j], out[i]];
  }
  return out;
}
