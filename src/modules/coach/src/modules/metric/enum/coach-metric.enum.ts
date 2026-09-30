/**
 * Counters that measure the COACH, not the reader.
 *
 * Both exist because the failure they watch for is systemic rather than
 * individual: one rejected draft is a bad guess, a high rate means the drafting
 * beat is wrong for everybody. They are counts by week with no user attached —
 * there is nothing here to profile a person with, and nothing that should be.
 */
export enum CoachMetricKind {
  /** ⑧ — the reader said the whole two-column draft was not theirs. */
  DRAFT_REJECTED = 'draft_rejected',
  /** Nhịp 4 — the reader asked for a keypoint in simpler words. */
  EXPLAIN_AGAIN = 'explain_again',
  /** Nhịp 3 — a draft the reader accepted without moving a single line. */
  DRAFT_UNTOUCHED = 'draft_untouched',
  /** Nhịp 3 — a draft the reader did move lines in. The pair gives the rate. */
  DRAFT_EDITED = 'draft_edited',
  /**
   * Nhịp 2 — the guard caught a banned meaning-question and made the model
   * write again. A rising rate means the beat's instruction is losing, which is
   * a prompt to fix rather than a reader to worry about.
   */
  BANNED_QUESTION = 'banned_question',
  /** Nhịp 2 — the model asked a banned question twice, so the fixed line ran. */
  BANNED_QUESTION_FALLBACK = 'banned_question_fallback',
  /**
   * A reply opened by handing the reader their own sentence back, and had to be
   * written again. Rising means the prompts are not carrying the ban.
   */
  ECHOED_READER = 'echoed_reader',
  /**
   * The reader pressed "đổi" on the habit chip.
   *
   * `ti_le_doi_habit_thu_cong` — the % of sessions where the silent match was
   * wrong enough that somebody fixed it by hand. The only direct measure of
   * that step's accuracy, which is otherwise invisible.
   */
  HABIT_CHANGED = 'habit_changed',

  // ---- funnel (2026-08-26, hướng đi) --------------------------------------
  // The counters above say whether the Coach TALKS well. These say whether
  // anyone gets anywhere: how often a door opens, how often the commitment is
  // taken, how the check-ins split, whether the course card is ever opened.
  // Still weekly, still no user attached — a rate, never a record.

  /** A session opened. `refId` = `entry:tier` (e.g. `home:B`). */
  SESSION_OPENED = 'session_opened',
  PLAN_ASK_YES = 'plan_ask_yes',
  PLAN_ASK_NO = 'plan_ask_no',
  INTENT_DONE = 'intent_done',
  INTENT_MISSED = 'intent_missed',
  INTENT_NONE = 'intent_none',
  /** A scene answered (first answer only — the one that is filed). */
  SCENE_ANSWERED = 'scene_answered',
  /** The course card reached the thread. `refId` = the reason key. */
  COURSE_SHOWN = 'course_shown',
  COURSE_OPENED = 'course_opened',
  COURSE_SAVED = 'course_saved',
  COURSE_SKIPPED = 'course_skipped',
  /** ②A after "có dịp mà chưa làm": took the smaller commitment · kept the old. */
  SHRINK_ACCEPTED = 'shrink_accepted',
  SHRINK_KEPT = 'shrink_kept',
}
