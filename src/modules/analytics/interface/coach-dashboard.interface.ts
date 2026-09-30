import { IDashboardRange } from './dashboard.interface';

// Shapes returned by the Coach statistics page. Like the rest of the dashboard,
// every rate is `null` rather than 0 when there is no denominator — printing 0%
// for "we have not measured this yet" is how a dashboard lies, and the Coach's
// tracking is new enough that most ranges will genuinely have nothing.

/**
 * Both units, always, because the page needs each in a different place.
 *
 * `events` is "lượt" — how many times the thing happened. `users` is how many
 * distinct people it happened to. A Coach session is not a person: somebody who
 * opens the sheet every evening is one user and thirty sessions, so a panel that
 * reported only one of these would answer half the questions asked of it.
 */
export interface ICoachEventCount {
  key: string;
  label: string;
  event: string;
  hint?: string;
  events: number;
  users: number;
}

/**
 * One step of a door funnel.
 *
 * Pass rates here are computed on **users**, not events: a bubble is seen many
 * times a day by the same person, so "views → clicks" on raw counts measures
 * how often the shell rebuilt rather than how persuasive the bubble is.
 */
export interface ICoachFunnelStep extends ICoachEventCount {
  /** Share of the first step's users still present, 0..1. */
  passRate: number | null;
  /** Users lost since the previous step. */
  dropUsers: number;
  dropRate: number | null;
}

/** One row of a `params.<field>` breakdown. */
export interface ICoachBreakdownRow {
  /** The raw param value. Empty string when the event carried none. */
  id: string;
  label: string;
  events: number;
  users: number;
  /** Share of the breakdown's own total, 0..1. */
  share: number | null;
}

/** Distribution of a numeric param — turn count, session length. */
export interface ICoachNumericStats {
  count: number;
  mean: number | null;
  median: number | null;
  p90: number | null;
}

/** How one door's sessions ended. */
export interface ICoachOutcomeRow {
  id: string;
  label: string;
  completed: number;
  abandoned: number;
  total: number;
  completionRate: number | null;
}

export interface ICoachDoorsPanel {
  /** Bong bóng trên shell → phiên mở được. */
  bubble: ICoachFunnelStep[];
  /** Màn mời sau keypoint → nhận lời. */
  invite: ICoachFunnelStep[];
  /** Counted beside the funnels, never inside them — these are ways in that failed. */
  misses: ICoachEventCount[];
  /** Phiên mở được, tách theo cửa. */
  byEntry: ICoachBreakdownRow[];
  /** Vì sao cửa mở ra sự im lặng. */
  silentReasons: ICoachBreakdownRow[];
}

export interface ICoachInSessionPanel {
  turns: ICoachEventCount;
  failed: ICoachEventCount;
  expired: ICoachEventCount;
  /** failed ÷ (sent + failed) — the share of attempts that never landed. */
  failureRate: number | null;
  byKind: ICoachBreakdownRow[];
  errorTypes: ICoachBreakdownRow[];
  /** Which beat the sheet was parked at when somebody left. */
  exitStep: ICoachBreakdownRow[];
}

export interface ICoachEndingTotals {
  /** `coach_scr_view` minus the automatic 48h re-opens. */
  opened: number;
  completed: number;
  abandoned: number;
  completionRate: number | null;
}

export interface ICoachEndingPanel extends ICoachEndingTotals {
  /** Re-opened automatically after the 48h expiry — not somebody deciding to. */
  reopened: number;
  /** Picked up a session that was already in progress. */
  resumed: number;
  /** Every `coach_scr_exit` — the denominator `completionRate` is measured on. */
  exits: number;
  /**
   * Opens with no exit event to match.
   *
   * The app is killed, the network drops, the process is reaped — the session
   * is simply never heard from again. Reported rather than folded into
   * "abandoned", because the two mean different things and guessing which
   * would make the completion rate a fiction.
   */
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
  /** Đi hết đường hay bỏ dở, tách theo cửa vào. */
  byEntry: ICoachOutcomeRow[];
  /** Luồng 6 — lời níu khi đóng giữa chừng. */
  plea: {
    shown: number;
    stay: number;
    leave: number;
    /** stay ÷ (stay + leave), not ÷ shown: a plea nobody answered proves nothing. */
    stayRate: number | null;
  };
}

export interface ICoachSurfacesPanel {
  items: ICoachEventCount[];
  rating: {
    /** 👍 / 👎, from the `thumb` param of a `kind=rating` turn. */
    thumbs: ICoachBreakdownRow[];
    /** The five closed chip ids behind a 👎. */
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
}

export interface ICoachStatsPage {
  range: IDashboardRange;
  compareRange: IDashboardRange | null;
  /**
   * False when the range holds no Coach event at all.
   *
   * The panel must say "chưa có dữ liệu" rather than draw a page of zeroes:
   * Coach tracking shipped on 2026-09-04 and is not in a production build yet,
   * so an empty prod range is the expected answer, not a broken query.
   */
  hasData: boolean;
  doors: ICoachDoorsPanel;
  inSession: ICoachInSessionPanel;
  ending: ICoachEndingPanel;
  surfaces: ICoachSurfacesPanel;
}
