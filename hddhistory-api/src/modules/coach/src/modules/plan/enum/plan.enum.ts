export enum CoachPlanStatus {
  /** Waiting to be asked back about. The only status ④ pushes for. */
  PENDING = 'pending',
  /** The reader told us they did it — there is a `coach_evidence` row. */
  DONE = 'done',
  /** Superseded by a newer commitment for the same habit. */
  REPLACED = 'replaced',
  /**
   * Three consecutive "no occasion came up" answers.
   *
   * Not `failed` and not `abandoned`. The commitment was never wrong — the
   * situation simply never arrived — and the vocabulary has to say so, because
   * this word ends up in front of the reader eventually.
   */
  SLEEPING = 'sleeping',
}

/** Which door the commitment was made at. Feeds "where do plans come from". */
export enum CoachPlanSource {
  LESSON_END = 'lesson_end',
  NAV_HABIT = 'nav_habit',
  HOME_TIER_A = 'home_tier_a',
  HOME_TIER_B = 'home_tier_b',
  HOME_TIER_C = 'home_tier_c',
  /** RETIRED (design v2): no shrunk commitment is proposed any more. */
  SHRINK = 'check_in_shrink',
  /** ④ — made after replaying a scene from three weeks ago. */
  RETRY = 'retry',
}

/**
 * The reader's last answer to "has there been an occasion yet?".
 *
 * `MISSED` is explicitly not a failure state — the flow's own words are "có dịp
 * mà chưa làm là chuyện thường". It resets the sleep counter exactly like
 * `DONE` does, because both mean the context is still live.
 */
export enum CoachPlanAnswer {
  DONE = 'done',
  MISSED = 'missed',
  NONE = 'none',
}

/** The three schedule shapes the sheet offers. Expanded by `matchesReminderDay`. */
export enum CoachReminderDays {
  /**
   * "Chỉ một lần" — one specific local date, then never again.
   *
   * The date lives in `ICoachPlanReminder.onceDate`; the dispatcher matches it
   * against the reader's OWN calendar day, so it cannot re-fire tomorrow.
   */
  ONCE = 'once',
  DAILY = 'daily',
  WEEKDAYS = 'weekdays',
  WEEKENDS = 'weekends',
  /** "tự chọn" — the reader picks weekdays; see `ICoachPlanReminder.customDays`. */
  CUSTOM = 'custom',
}
