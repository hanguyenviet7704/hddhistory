import { IDashboardRange } from "./dashboard.interface";

// Mirror of `hddhistory-api/src/modules/analytics/interface/coach-dashboard.interface.ts`
// plus the weekly-counter payload from `GET /coach-metrics`.
//
// Every rate is `number | null` for the same reason it is on the server: a rate
// with no denominator has not been measured, and rendering it as 0% would be a
// lie the page tells confidently. `formatPercent` prints null as an em dash.

/**
 * Both units, always. `events` is "lượt" — how many times it happened; `users`
 * is how many distinct people. A Coach session is not a person, so a panel
 * showing only one of them answers half the question.
 */
export interface ICoachEventCount {
  key: string;
  label: string;
  event: string;
  hint?: string;
  events: number;
  users: number;
}

export interface ICoachFunnelStep extends ICoachEventCount {
  passRate: number | null;
  dropUsers: number;
  dropRate: number | null;
}

export interface ICoachBreakdownRow {
  id: string;
  label: string;
  events: number;
  users: number;
  share: number | null;
}

export interface ICoachNumericStats {
  count: number;
  mean: number | null;
  median: number | null;
  p90: number | null;
}

export interface ICoachOutcomeRow {
  id: string;
  label: string;
  completed: number;
  abandoned: number;
  total: number;
  completionRate: number | null;
}

export interface ICoachEndingTotals {
  opened: number;
  completed: number;
  abandoned: number;
  completionRate: number | null;
}

export interface ICoachStatsPage {
  range: IDashboardRange;
  compareRange: IDashboardRange | null;
  hasData: boolean;

  doors: {
    bubble: ICoachFunnelStep[];
    invite: ICoachFunnelStep[];
    misses: ICoachEventCount[];
    byEntry: ICoachBreakdownRow[];
    silentReasons: ICoachBreakdownRow[];
  };

  inSession: {
    turns: ICoachEventCount;
    failed: ICoachEventCount;
    expired: ICoachEventCount;
    failureRate: number | null;
    byKind: ICoachBreakdownRow[];
    errorTypes: ICoachBreakdownRow[];
    exitStep: ICoachBreakdownRow[];
  };

  ending: ICoachEndingTotals & {
    reopened: number;
    resumed: number;
    exits: number;
    /** Opens with no exit event: app killed, network dropped. Not "abandoned". */
    unaccounted: number;
    previous: ICoachEndingTotals | null;
    turnCount: {
      completed: ICoachNumericStats;
      abandoned: ICoachNumericStats;
    };
    durationSec: {
      completed: ICoachNumericStats;
      abandoned: ICoachNumericStats;
    };
    byEntry: ICoachOutcomeRow[];
    plea: {
      shown: number;
      stay: number;
      leave: number;
      stayRate: number | null;
    };
  };

  surfaces: {
    items: ICoachEventCount[];
    rating: {
      thumbs: ICoachBreakdownRow[];
      chips: ICoachBreakdownRow[];
      thumbsUpRate: number | null;
    };
    quiz: {
      runs: number;
      questions: number;
      passed: number;
      passRate: number | null;
    };
    mic: {
      starts: number;
      granted: number;
      grantRate: number | null;
      done: number;
      withText: number;
      textRate: number | null;
    };
  };
}

// ------------------------------------------------- weekly server counters

export type CoachMetricGroup = "quality" | "funnel";

export interface ICoachMetricItem {
  kind: string;
  label: string;
  group: CoachMetricGroup;
  /** What `refId` splits this counter by, when it carries one. */
  refLabel: string | null;
  count: number;
  refs: { refId: string; count: number }[];
}

/**
 * One ISO week of the Coach's own counters.
 *
 * Keyed by week rather than by the page's date range on purpose — the server
 * writes them per ISO week and there is no day inside them to slice. The block
 * gets its own picker instead of being folded into the range above, because
 * pretending a week is a date range is how a number ends up meaning nothing.
 */
export interface ICoachMetricsWeek {
  isoWeek: string;
  /** Weeks that actually hold counts, newest first — the picker's options. */
  weeks: string[];
  hasData: boolean;
  items: ICoachMetricItem[];
}
