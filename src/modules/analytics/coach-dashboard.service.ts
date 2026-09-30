import { Injectable } from '@nestjs/common';

import {
  COACH_BUBBLE_FUNNEL,
  COACH_DOOR_MISSES,
  COACH_ENTRY_LABELS,
  COACH_EXIT_LEAVE,
  COACH_EXIT_PLEA_VIEW,
  COACH_EXIT_STAY,
  COACH_INVITE_FUNNEL,
  COACH_OPEN_SILENT,
  COACH_RATING_CHIP_LABELS,
  COACH_SCR_EXIT,
  COACH_SCR_VIEW,
  COACH_SESSION_EXPIRED,
  COACH_SILENT_REASON_LABELS,
  COACH_STEP_BREAKDOWN_LIMIT,
  COACH_STEP_LABELS,
  COACH_SURFACES,
  COACH_THUMB_LABELS,
  COACH_TURN_FAILED,
  COACH_TURN_KIND_LABELS,
  COACH_TURN_SEND,
  PARAM_DURATION_SEC,
  PARAM_ENTRY,
  PARAM_ERROR_TYPE,
  PARAM_IS_ENDED,
  PARAM_IS_REOPEN,
  PARAM_IS_RESUMED,
  PARAM_KIND,
  PARAM_REASON_KEY,
  PARAM_STEP,
  PARAM_THUMB,
  PARAM_TURN_COUNT,
} from './constant/coach-dashboard.constant';
import {
  previousDashboardPeriod,
  rateOf,
  resolveDashboardFilter,
  toDashboardRange,
} from './dashboard-period.helper';
import { GetDashboardDto } from './dto/get-dashboard.dto';
import {
  ICoachBreakdownRow,
  ICoachEndingTotals,
  ICoachEventCount,
  ICoachFunnelStep,
  ICoachNumericStats,
  ICoachOutcomeRow,
  ICoachStatsPage,
} from './interface/coach-dashboard.interface';
import { AnalyticsDashboardRepository } from './repository/analytics-dashboard.repository';
import {
  CoachDashboardRepository,
  ICoachBreakdownCount,
} from './repository/coach-dashboard.repository';

/** Shape of one entry in the constant file's label tables. */
type LabelledEvent = {
  readonly key: string;
  readonly label: string;
  readonly event: string;
  readonly hint?: string;
};

type EventTotals = Record<string, { users: number; events: number }>;

const EMPTY_STATS: ICoachNumericStats = {
  count: 0,
  mean: null,
  median: null,
  p90: null,
};

/** Mongo hands booleans back as the strings the breakdown stringified them to. */
const TRUE_ID = 'true';
const FALSE_ID = 'false';

/**
 * Assembles the Coach statistics page.
 *
 * Everything this class adds on top of the two repositories is interpretation,
 * and three judgements in it are worth stating out loud because a different
 * choice would quietly change what the page means:
 *
 * 1. **Door funnels are rated on people, session outcomes on sessions.** A
 *    bubble is seen many times a day by the same reader, so "views → clicks"
 *    over raw counts would measure how often the shell rebuilt. A session, by
 *    contrast, is the unit of "did this go anywhere" — one reader who opens the
 *    Coach every evening is one person and thirty journeys.
 * 2. **Completion is measured against sessions that reported an end**, not
 *    against opens. The app is killed, the network drops, the process is
 *    reaped; those sessions are counted separately as `unaccounted` rather than
 *    guessed at, because folding them into "abandoned" would invent a failure
 *    nobody observed.
 * 3. **A rate with no denominator is `null`, never 0.** Coach tracking shipped
 *    on 2026-09-04 and is not in a production build yet, so an empty range is
 *    the expected answer and the panel has to be able to say so.
 */
@Injectable()
export class CoachDashboardService {
  constructor(
    private readonly repository: CoachDashboardRepository,
    private readonly analytics: AnalyticsDashboardRepository,
  ) {}

  // ------------------------------------------------------------- plumbing

  /** Every event the page counts — one `eventTotals` pass rather than twenty. */
  private countedEvents(): string[] {
    return [
      ...COACH_BUBBLE_FUNNEL.map((step) => step.event),
      ...COACH_INVITE_FUNNEL.map((step) => step.event),
      ...COACH_DOOR_MISSES.map((miss) => miss.event),
      ...COACH_SURFACES.map((surface) => surface.event),
      COACH_SCR_EXIT,
      COACH_TURN_SEND,
      COACH_TURN_FAILED,
      COACH_SESSION_EXPIRED,
      COACH_EXIT_PLEA_VIEW,
      COACH_EXIT_STAY,
      COACH_EXIT_LEAVE,
    ];
  }

  private countOf(
    totals: EventTotals,
    entry: LabelledEvent,
  ): ICoachEventCount {
    const row = totals[entry.event];

    return {
      key: entry.key,
      label: entry.label,
      event: entry.event,
      ...(entry.hint ? { hint: entry.hint } : {}),
      events: row?.events ?? 0,
      users: row?.users ?? 0,
    };
  }

  private eventsOf(totals: EventTotals, event: string): number {
    return totals[event]?.events ?? 0;
  }

  /**
   * A funnel, rated on distinct users.
   *
   * The first step is the denominator for every `passRate`, and the previous
   * step for every `dropRate` — the two answer different questions ("how much
   * of the top is still here" vs "what did this step cost").
   */
  private toFunnel(
    totals: EventTotals,
    steps: readonly LabelledEvent[],
  ): ICoachFunnelStep[] {
    const counts = steps.map((step) => this.countOf(totals, step));
    const base = counts[0]?.users ?? 0;

    return counts.map((count, index) => {
      const previous = index === 0 ? null : counts[index - 1];
      // Clamped: a later step can out-count an earlier one at a range boundary,
      // and a negative "people lost" is noise, not a finding.
      const dropUsers = previous
        ? Math.max(0, previous.users - count.users)
        : 0;

      return {
        ...count,
        passRate: rateOf(count.users, base),
        dropUsers,
        dropRate: previous ? rateOf(dropUsers, previous.users) : null,
      };
    });
  }

  /**
   * Raw param ids become labelled rows; an unknown id keeps its own name.
   *
   * `total` is the share's denominator and must be passed whenever the
   * breakdown can be truncated. `coach_scr_exit` carries a `step` out of 47
   * possible ones, so summing the twelve rows that came back would make each
   * share a fraction of the top twelve — the rows would add to 100% while
   * describing a slice of the data. Passing the real total (every exit) keeps
   * each percentage meaning what it says, and lets the visible shares fall
   * short of 100% honestly.
   */
  private toBreakdown(
    rows: ICoachBreakdownCount[],
    labels: Record<string, string>,
    total?: number,
  ): ICoachBreakdownRow[] {
    const denominator =
      total ?? rows.reduce((sum, row) => sum + row.events, 0);

    return rows.map((row) => ({
      id: row.id,
      label: labels[row.id] ?? (row.id || '(không có)'),
      events: row.events,
      users: row.users,
      share: rateOf(row.events, denominator),
    }));
  }

  /** The `events` count of one id inside a breakdown — 0 when it never appeared. */
  private pick(rows: ICoachBreakdownCount[], id: string): number {
    return rows.find((row) => row.id === id)?.events ?? 0;
  }

  /**
   * The three headline numbers, for one period.
   *
   * `opened` drops the automatic 48h re-open: the app fires `coach_scr_view`
   * for it too, but nobody decided to open anything.
   */
  private endingTotals(
    totals: EventTotals,
    exitRows: ICoachBreakdownCount[],
    reopenRows: ICoachBreakdownCount[],
  ): ICoachEndingTotals & { exits: number; reopened: number } {
    const reopened = this.pick(reopenRows, TRUE_ID);
    const opened = Math.max(
      0,
      this.eventsOf(totals, COACH_SCR_VIEW) - reopened,
    );
    const completed = this.pick(exitRows, TRUE_ID);
    const abandoned = this.pick(exitRows, FALSE_ID);
    const exits = this.eventsOf(totals, COACH_SCR_EXIT);

    return {
      opened,
      reopened,
      completed,
      abandoned,
      exits,
      completionRate: rateOf(completed, exits),
    };
  }

  // ------------------------------------------------------------------ page

  async getStats(dto: GetDashboardDto): Promise<ICoachStatsPage> {
    const filter = resolveDashboardFilter(dto);
    const previous = dto.compare ? previousDashboardPeriod(filter) : null;

    const [
      totals,
      previousTotals,
      exitRows,
      previousExitRows,
      reopenRows,
      previousReopenRows,
      resumeRows,
      entryRows,
      silentRows,
      kindRows,
      errorRows,
      stepRows,
      thumbRows,
      chipRows,
      turnStats,
      durationStats,
      outcomeRows,
      quiz,
      mic,
    ] = await Promise.all([
      this.analytics.eventTotals(filter, this.countedEvents()),
      previous
        ? this.analytics.eventTotals(previous, this.countedEvents())
        : null,
      this.repository.paramBreakdown(filter, COACH_SCR_EXIT, PARAM_IS_ENDED),
      previous
        ? this.repository.paramBreakdown(
            previous,
            COACH_SCR_EXIT,
            PARAM_IS_ENDED,
          )
        : null,
      this.repository.paramBreakdown(filter, COACH_SCR_VIEW, PARAM_IS_REOPEN),
      previous
        ? this.repository.paramBreakdown(
            previous,
            COACH_SCR_VIEW,
            PARAM_IS_REOPEN,
          )
        : null,
      this.repository.paramBreakdown(filter, COACH_SCR_VIEW, PARAM_IS_RESUMED),
      // The door split counts sessions somebody chose to open, so the automatic
      // re-opens are filtered out here the same way they are above.
      this.repository.paramBreakdown(filter, COACH_SCR_VIEW, PARAM_ENTRY, {
        match: { [PARAM_IS_REOPEN]: { $ne: true } } as any,
      }),
      this.repository.paramBreakdown(
        filter,
        COACH_OPEN_SILENT,
        PARAM_REASON_KEY,
      ),
      this.repository.paramBreakdown(filter, COACH_TURN_SEND, PARAM_KIND),
      this.repository.paramBreakdown(
        filter,
        COACH_TURN_FAILED,
        PARAM_ERROR_TYPE,
      ),
      // Wider than the default: there are 47 possible steps, and a top-12
      // cut would hide beats that matter precisely because they are rare.
      this.repository.paramBreakdown(filter, COACH_SCR_EXIT, PARAM_STEP, {
        limit: COACH_STEP_BREAKDOWN_LIMIT,
      }),
      this.repository.paramBreakdown(filter, COACH_TURN_SEND, PARAM_THUMB, {
        match: { [PARAM_KIND]: 'rating' } as any,
      }),
      this.repository.chipBreakdown(filter),
      this.repository.numericStatsByOutcome(
        filter,
        COACH_SCR_EXIT,
        PARAM_TURN_COUNT,
        PARAM_IS_ENDED,
      ),
      this.repository.numericStatsByOutcome(
        filter,
        COACH_SCR_EXIT,
        PARAM_DURATION_SEC,
        PARAM_IS_ENDED,
      ),
      this.repository.outcomeByParam(
        filter,
        COACH_SCR_EXIT,
        PARAM_IS_ENDED,
        PARAM_ENTRY,
      ),
      this.repository.quizTotals(filter),
      this.repository.micTotals(filter),
    ]);

    const ending = this.endingTotals(totals, exitRows, reopenRows);
    const previousEnding =
      previousTotals && previousExitRows && previousReopenRows
        ? this.endingTotals(
            previousTotals,
            previousExitRows,
            previousReopenRows,
          )
        : null;

    const turnsSent = this.eventsOf(totals, COACH_TURN_SEND);
    const turnsFailed = this.eventsOf(totals, COACH_TURN_FAILED);
    const stay = this.eventsOf(totals, COACH_EXIT_STAY);
    const leave = this.eventsOf(totals, COACH_EXIT_LEAVE);
    const thumbs = this.toBreakdown(thumbRows, COACH_THUMB_LABELS);
    const thumbsUp = this.pick(thumbRows, 'up');
    const thumbsDown = this.pick(thumbRows, 'down');

    return {
      range: toDashboardRange(filter),
      compareRange: previous ? toDashboardRange(previous) : null,
      hasData: this.hasData(totals, [entryRows, kindRows, exitRows, stepRows]),

      doors: {
        bubble: this.toFunnel(totals, COACH_BUBBLE_FUNNEL),
        invite: this.toFunnel(totals, COACH_INVITE_FUNNEL),
        misses: COACH_DOOR_MISSES.map((miss) => this.countOf(totals, miss)),
        byEntry: this.toBreakdown(entryRows, COACH_ENTRY_LABELS),
        silentReasons: this.toBreakdown(silentRows, COACH_SILENT_REASON_LABELS),
      },

      inSession: {
        turns: this.countOf(totals, {
          key: 'turnSend',
          label: 'Lượt gửi',
          event: COACH_TURN_SEND,
        }),
        failed: this.countOf(totals, {
          key: 'turnFailed',
          label: 'Lượt gửi hỏng',
          event: COACH_TURN_FAILED,
        }),
        expired: this.countOf(totals, {
          key: 'sessionExpired',
          label: 'Phiên hết hạn giữa chừng',
          event: COACH_SESSION_EXPIRED,
        }),
        // Against every attempt, sent or not: a reader who pressed send and got
        // nothing back made an attempt, and leaving it out of the denominator
        // would make the rate smaller the worse things got.
        failureRate: rateOf(turnsFailed, turnsSent + turnsFailed),
        byKind: this.toBreakdown(kindRows, COACH_TURN_KIND_LABELS, turnsSent),
        errorTypes: this.toBreakdown(errorRows, {}, turnsFailed),
        exitStep: this.toBreakdown(stepRows, COACH_STEP_LABELS, ending.exits),
      },

      ending: {
        ...ending,
        resumed: this.pick(resumeRows, TRUE_ID),
        unaccounted: Math.max(0, ending.opened - ending.exits),
        previous: previousEnding
          ? {
              opened: previousEnding.opened,
              completed: previousEnding.completed,
              abandoned: previousEnding.abandoned,
              completionRate: previousEnding.completionRate,
            }
          : null,
        turnCount: {
          completed: turnStats[TRUE_ID] ?? EMPTY_STATS,
          abandoned: turnStats[FALSE_ID] ?? EMPTY_STATS,
        },
        durationSec: {
          completed: durationStats[TRUE_ID] ?? EMPTY_STATS,
          abandoned: durationStats[FALSE_ID] ?? EMPTY_STATS,
        },
        byEntry: this.toOutcomeRows(outcomeRows),
        plea: {
          shown: this.eventsOf(totals, COACH_EXIT_PLEA_VIEW),
          stay,
          leave,
          // Against the people who answered, not the people who saw it: a plea
          // somebody swiped past proves nothing either way.
          stayRate: rateOf(stay, stay + leave),
        },
      },

      surfaces: {
        items: COACH_SURFACES.map((surface) => this.countOf(totals, surface)),
        rating: {
          thumbs,
          chips: this.toBreakdown(chipRows, COACH_RATING_CHIP_LABELS),
          thumbsUpRate: rateOf(thumbsUp, thumbsUp + thumbsDown),
        },
        quiz: {
          ...quiz,
          passRate: rateOf(quiz.passed, quiz.questions),
        },
        mic: {
          starts: mic.starts,
          granted: mic.granted,
          grantRate: rateOf(mic.granted, mic.starts),
          done: mic.done,
          withText: mic.withText,
          textRate: rateOf(mic.withText, mic.done),
        },
      },
    };
  }

  private toOutcomeRows(
    rows: { id: string; completed: number; abandoned: number }[],
  ): ICoachOutcomeRow[] {
    return rows.map((row) => {
      const total = row.completed + row.abandoned;

      return {
        id: row.id,
        label: COACH_ENTRY_LABELS[row.id] ?? (row.id || '(không rõ cửa)'),
        completed: row.completed,
        abandoned: row.abandoned,
        total,
        completionRate: rateOf(row.completed, total),
      };
    });
  }

  /**
   * Whether the range holds any Coach traffic at all.
   *
   * Checked across both the counts and the breakdowns rather than on one
   * number: the point is to let the panel say "chưa có dữ liệu" instead of
   * drawing a page of honest-looking zeroes, and it should say that only when
   * there is genuinely nothing.
   */
  private hasData(
    totals: EventTotals,
    breakdowns: ICoachBreakdownCount[][],
  ): boolean {
    const counted = Object.values(totals).some((row) => row.events > 0);

    return counted || breakdowns.some((rows) => rows.length > 0);
  }
}
