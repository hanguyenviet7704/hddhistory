import { DayLogMoment } from '../enum/day-log.enum';

/**
 * One line in the reader's day, at user+day grain.
 *
 * Deliberately not merged into `habit_checkins.mood`, which is a different
 * grain and a different question: that one is the mood attached to a JOURNAL
 * practice of ONE habit. This is "how is your day", which belongs to nobody's
 * habit.
 *
 * `mood` and `note` are both optional because the two things that write here
 * are independent: the mood prompt writes a mood with no note, and ⑥ (the
 * 20-second way out) writes a note with no mood.
 */
export interface IUserDayLog {
  userId: string;
  /** UTC-midnight date-only, the same normalisation `habit_checkins` uses. */
  date: Date;
  moment: DayLogMoment;
  mood?: number | null;
  /** The ⑥ jot — the reader's own line, kept because it is their words. */
  note?: string | null;
  sessionId?: string | null;
}
