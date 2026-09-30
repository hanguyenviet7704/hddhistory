/**
 * When in the session the mood was asked.
 *
 * The pair is the point: the delta between them is the only signal we have for
 * "did this conversation help", and it is the stopping criterion for the whole
 * feature. One reading on its own says nothing.
 */
export enum DayLogMoment {
  /** Asked once per day, on the first session of that day. */
  START = 'start',
  /** Asked at the end of every session. */
  END = 'end',
}
