/**
 * The three chips on the Saved screen. Derived from the user's progress against
 * the course at read time — nothing is stored on the bookmark row itself, so a
 * course moves between buckets as the user studies it.
 */
export enum SavedCourseStatus {
  /** Saved but never opened — no progress row, or nothing passed yet. */
  UP_NEXT = 'up_next',
  IN_PROGRESS = 'in_progress',
  FINISHED = 'finished',
}
