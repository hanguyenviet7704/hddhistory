/** Courses shown inside one editor-curated strip. */
export const EXPLORE_COLLECTION_SIZE = 8;

/** Courses in the weekly-popular card and in the "because you learned" strip. */
export const EXPLORE_WEEKLY_TOP_SIZE = 3;
export const EXPLORE_BECAUSE_YOU_SIZE = 3;

/**
 * The week the popular strip reports on, as a timezone.
 *
 * Fixed rather than per-viewer: the strip is a single ranking shown to
 * everybody, so it has to be counted over one window. The audience is
 * predominantly Vietnamese, so the week turns at midnight Hanoi time.
 */
export const EXPLORE_WEEK_TIMEZONE = 'Asia/Ho_Chi_Minh';
