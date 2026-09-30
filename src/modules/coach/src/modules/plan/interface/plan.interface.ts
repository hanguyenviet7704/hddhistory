import {
  CoachPlanAnswer,
  CoachPlanSource,
  CoachPlanStatus,
  CoachReminderDays,
} from '../enum/plan.enum';

/**
 * When ④ fires, embedded rather than a table of its own: it is 1:1 with the
 * plan, always read with it, and dies with it. A separate collection would only
 * add a join and a way to orphan rows when a commitment closes.
 */
export interface ICoachPlanReminder {
  enabled: boolean;
  /** Local hour 0-23, the reader's own choice — NOT a per-type constant. */
  hour: number;
  minute: number;
  days: CoachReminderDays;
  /** "Chỉ một lần": the reader-local date, YYYY-MM-DD. Read only when `days` is ONCE. */
  onceDate?: string | null;

  /** ISO weekdays 1 (Mon) … 7 (Sun). Read only when `days` is CUSTOM. */
  customDays?: number[];
}

export interface ICoachPlan {
  userId: string;
  /**
   * "When X" and "I will Y", both in the reader's own words.
   *
   * Never normalised, never rewritten by the model, never translated. The push
   * notification quotes them back verbatim, and the whole mechanism depends on
   * the reader recognising their own sentence.
   */
  context: string;
  action: string;
  status: CoachPlanStatus;
  source: CoachPlanSource;
  habitId?: string | null;
  /** Guards "ask about each plan at most once a day". */
  lastAskedAt?: Date | null;
  lastAnswer?: CoachPlanAnswer | null;
  consecutiveNoOccasion: number;
  reminder: ICoachPlanReminder;
  /** Set when ④ last pushed, so the one-a-day cap is answerable. */
  lastNotifiedAt?: Date | null;
}
