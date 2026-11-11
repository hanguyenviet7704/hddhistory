import { CoachMetricKind } from '../enum/coach-metric.enum';

export interface ICoachMetric {
  kind: CoachMetricKind;
  /**
   * What the count is about, when that is a thing — the keypoint someone asked
   * to have re-explained. Null for counters that are about the flow itself.
   */
  refId?: string | null;
  /** ISO week, `YYYY-Www`. Weekly because that is the grain a fix is decided at. */
  isoWeek: string;
  count: number;
}
