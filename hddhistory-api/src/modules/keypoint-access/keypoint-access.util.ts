/**
 * Which calendar day a moment falls on FOR THE READER, as `YYYY-MM-DD`.
 *
 * The offset comes from the request (`x-timezone-offset`, minutes ahead of UTC —
 * Vietnam is 420), the same header the learning streak already buckets its days
 * by. Using server time instead would file a Vietnamese reader's 00:30 session
 * under the previous day, which is precisely when someone notices their free
 * keypoint is missing and files a bug.
 *
 * A STRING, not a Date range: the day is what the unique index enforces one claim
 * per, and a string comparison cannot drift the way two Date boundaries can.
 */
export function dayKeyFor(now: Date, offsetMinutes: number): string {
  const shifted = new Date(now.getTime() + offsetMinutes * 60_000);

  // getUTC* on a shifted instant = the reader's own wall clock.
  const year = shifted.getUTCFullYear();
  const month = `${shifted.getUTCMonth() + 1}`.padStart(2, '0');
  const day = `${shifted.getUTCDate()}`.padStart(2, '0');

  return `${year}-${month}-${day}`;
}

/**
 * Real timezone offsets span UTC-12:00 to UTC+14:00. Anything outside that is a
 * malformed or hostile header, and clamping beats trusting it: the offset decides
 * which day a claim lands in, so an absurd value would hand out an extra free
 * keypoint every time it changed.
 */
const MIN_OFFSET_MINUTES = -12 * 60;
const MAX_OFFSET_MINUTES = 14 * 60;

/**
 * The reader's UTC offset in minutes, or 0 when the header is missing or unusable.
 *
 * 0 (UTC) rather than a guess at Vietnam: a wrong-but-plausible default is harder
 * to notice than a neutral one, and every real app build sends the header.
 */
export function resolveTimezoneOffsetMinutes(header?: string): number {
  const parsed = Number.parseInt((header ?? '').trim(), 10);
  if (!Number.isFinite(parsed)) return 0;

  return Math.min(Math.max(parsed, MIN_OFFSET_MINUTES), MAX_OFFSET_MINUTES);
}

/**
 * Marker the app puts in the ids it synthesises for a lesson the reader generated
 * (`UserLessonCourseMapper.idMarker`). Such a keypoint names nothing in the
 * catalogue.
 */
const USER_LESSON_ID_MARKER = '::user-lesson::';

/**
 * Whether this id belongs to a lesson the reader made rather than to catalogue
 * content.
 *
 * The quota rations how much NEW PUBLISHED content a free reader gets. A lesson
 * generated from a PDF they uploaded is not that, so it is never metered — and the
 * check lives here as well as in the app because this is a content gate: a client
 * that forgets the guard must not be able to charge someone for their own material.
 */
export function isUserLessonKeypointId(keypointId?: string): boolean {
  return (keypointId ?? '').includes(USER_LESSON_ID_MARKER);
}
