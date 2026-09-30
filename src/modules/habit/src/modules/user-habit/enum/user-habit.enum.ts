export enum UserHabitState {
  ACTIVE = 'active',
  DRAFT = 'draft',
  ARCHIVED = 'archived',
}

export enum HabitPackLength {
  THREE_DAYS = 3,
  SEVEN_DAYS = 7,
  FOURTEEN_DAYS = 14,
}

/**
 * How the user filed a day's check-in. `TAP` is the quick toggle on the Habit
 * tab's 7-day strip; the rest come from the "Practice now" flow, where the
 * picker asks "How do you want to check in?" — so a completed practice *is*
 * the day's check-in, not a separate activity.
 *
 * `JOURNAL` is native (mood + free text, no authored content). The remaining
 * values deliberately mirror `LearningItemType`, because a practice's method is
 * just the type of the `learning_item` it points at — which is what lets video
 * and roleplay practices ship without a schema change.
 */
export enum HabitCheckinMethod {
  TAP = 'tap',
  JOURNAL = 'journal',
  EXERCISE = 'exercise',
  VIDEO = 'video',
  ROLEPLAY = 'roleplay',
  /**
   * Filed by the AI Coach from the Habit screen (luồng 5, design 2026-09-03):
   * "Có, mình làm được" after one sentence about the occasion, or "Chưa, hôm
   * nay không có dịp" as done:false — "không bỏ trống ngày".
   */
  COACH = 'coach',
}
