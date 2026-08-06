export enum HabitStatus {
  DRAFT = "draft",
  PUBLISHED = "published",
}

/** State of a habit a user has adopted (user_habits.state). */
export enum UserHabitState {
  ACTIVE = "active",
  DRAFT = "draft",
  ARCHIVED = "archived",
}

/**
 * How a user filed a day's check-in. `TAP` is the quick toggle on the app's
 * 7-day strip; the rest come from the "Practice now" flow. Rows written before
 * practice shipped have no method at all — render those as Tap rather than
 * as unknown.
 */
export enum HabitCheckinMethod {
  TAP = "tap",
  JOURNAL = "journal",
  EXERCISE = "exercise",
  VIDEO = "video",
  ROLEPLAY = "roleplay",
}
