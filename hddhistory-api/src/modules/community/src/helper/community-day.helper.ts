/**
 * The UTC instant at which the caller's own calendar day began.
 *
 * Per-reader, unlike `startOfWeekUtc`, and deliberately so: the week counter it
 * serves is a stored number reset by a cron, so that boundary has to be one
 * fixed instant for everybody. "N hôm nay" is counted live per request, so it
 * can afford to mean the reader's today — and it has to, because a reader in
 * Tokyo being told what happened during the server's day is simply wrong.
 *
 * [tzOffsetMinutes] is minutes EAST of UTC, matching what the app sends
 * (`DateTime.now().timeZoneOffset.inMinutes`, 420 for Vietnam). 0 falls back to
 * the server's day, which is right only for a caller with no timezone to
 * declare — an older app build, or the admin panel.
 */
export function startOfLocalDayUtc(now: Date, tzOffsetMinutes: number): Date {
  const local = new Date(now.getTime() + tzOffsetMinutes * 60_000);
  const localMidnight = Date.UTC(
    local.getUTCFullYear(),
    local.getUTCMonth(),
    local.getUTCDate(),
  );

  return new Date(localMidnight - tzOffsetMinutes * 60_000);
}
