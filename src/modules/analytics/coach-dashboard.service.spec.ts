import { CoachDashboardService } from './coach-dashboard.service';
import { GetDashboardDto } from './dto/get-dashboard.dto';
import { AnalyticsDashboardRepository } from './repository/analytics-dashboard.repository';
import { CoachDashboardRepository } from './repository/coach-dashboard.repository';

/**
 * The arithmetic between the aggregations and the Coach panel.
 *
 * The pipelines themselves are exercised against a real Mongo; what is easy to
 * get wrong up here is the interpretation. Three things in particular, and each
 * has a test below:
 *
 * 1. A session that opened and never reported an exit is not an abandoned
 *    session — folding it in would make the completion rate a fiction.
 * 2. `coach_scr_view` fires for the automatic 48h re-open too, which is not
 *    somebody deciding to open the Coach.
 * 3. Coach tracking is new, so most ranges are genuinely empty. Empty must read
 *    as "chưa đo được", never as 0%.
 */
describe('CoachDashboardService', () => {
  let service: CoachDashboardService;
  let coach: jest.Mocked<Partial<CoachDashboardRepository>>;
  let dashboard: jest.Mocked<Partial<AnalyticsDashboardRepository>>;

  const dto = (overrides: Partial<GetDashboardDto> = {}): GetDashboardDto =>
    ({
      from: '2026-08-01T00:00:00.000Z',
      to: '2026-08-07T23:59:59.999Z',
      appEnv: 'prod',
      timezone: 'Asia/Ho_Chi_Minh',
      compare: false,
      ...overrides,
    }) as GetDashboardDto;

  const emptyStats = { count: 0, mean: null, median: null, p90: null };

  /** Every count zero — the shape a range with no Coach traffic returns. */
  const totalsOf = (overrides: Record<string, { events: number; users: number }> = {}) =>
    overrides;

  beforeEach(() => {
    coach = {
      paramBreakdown: jest.fn().mockResolvedValue([]),
      numericStatsByOutcome: jest.fn().mockResolvedValue({}),
      outcomeByParam: jest.fn().mockResolvedValue([]),
      chipBreakdown: jest.fn().mockResolvedValue([]),
      quizTotals: jest
        .fn()
        .mockResolvedValue({ runs: 0, questions: 0, passed: 0 }),
      micTotals: jest
        .fn()
        .mockResolvedValue({ starts: 0, granted: 0, done: 0, withText: 0 }),
    };
    dashboard = { eventTotals: jest.fn().mockResolvedValue({}) };

    service = new CoachDashboardService(
      coach as unknown as CoachDashboardRepository,
      dashboard as unknown as AnalyticsDashboardRepository,
    );
  });

  /** Aims one `paramBreakdown` mock at a specific (event, param) pair. */
  const breakdown = (
    rows: Record<string, { id: string; events: number; users: number }[]>,
  ) => {
    coach.paramBreakdown = jest.fn(
      async (_filter: any, event: string, path: string) =>
        rows[`${event}|${path}`] ?? [],
    ) as any;
  };

  describe('an empty range', () => {
    it('reports hasData false rather than a page of zeroes', async () => {
      const page = await service.getStats(dto());

      expect(page.hasData).toBe(false);
      expect(page.ending.completionRate).toBeNull();
      expect(page.inSession.failureRate).toBeNull();
      expect(page.surfaces.rating.thumbsUpRate).toBeNull();
      expect(page.ending.plea.stayRate).toBeNull();
    });

    it('gives every funnel step a null pass rate, not 0%', async () => {
      const page = await service.getStats(dto());

      expect(page.doors.bubble).toHaveLength(3);
      expect(page.doors.bubble.every((step) => step.passRate === null)).toBe(true);
    });
  });

  describe('the three headline numbers', () => {
    beforeEach(() => {
      dashboard.eventTotals = jest.fn().mockResolvedValue(
        totalsOf({
          coach_scr_view: { events: 100, users: 40 },
          coach_scr_exit: { events: 80, users: 35 },
        }),
      );
      breakdown({
        'coach_scr_exit|params.is_ended': [
          { id: 'true', events: 50, users: 25 },
          { id: 'false', events: 30, users: 20 },
        ],
        'coach_scr_view|params.is_reopen': [
          { id: 'true', events: 10, users: 8 },
          { id: 'false', events: 90, users: 38 },
        ],
      });
    });

    it('excludes automatic 48h re-opens from "mở phiên"', async () => {
      const page = await service.getStats(dto());

      expect(page.ending.reopened).toBe(10);
      expect(page.ending.opened).toBe(90);
    });

    it('measures completion against exits, not opens', async () => {
      const page = await service.getStats(dto());

      expect(page.ending.exits).toBe(80);
      expect(page.ending.completed).toBe(50);
      expect(page.ending.abandoned).toBe(30);
      // 50/80, not 50/90 — the ten sessions we never heard back from are not
      // evidence of anything.
      expect(page.ending.completionRate).toBeCloseTo(0.625);
    });

    it('reports opens with no exit separately from abandoned ones', async () => {
      const page = await service.getStats(dto());

      expect(page.ending.unaccounted).toBe(10);
    });

    it('never reports a negative unaccounted count', async () => {
      // More exits than opens is possible at a range boundary: a session opened
      // on the last day of the previous period closes inside this one.
      dashboard.eventTotals = jest.fn().mockResolvedValue(
        totalsOf({
          coach_scr_view: { events: 5, users: 3 },
          coach_scr_exit: { events: 9, users: 4 },
        }),
      );

      const page = await service.getStats(dto());

      expect(page.ending.unaccounted).toBe(0);
    });
  });

  describe('door funnels', () => {
    it('computes pass rates on distinct users, not raw events', async () => {
      dashboard.eventTotals = jest.fn().mockResolvedValue(
        totalsOf({
          // 900 views from only 100 people — a bubble is seen many times a day.
          coach_bubble_view: { events: 900, users: 100 },
          coach_bubble_click: { events: 60, users: 50 },
          coach_scr_view: { events: 55, users: 45 },
        }),
      );

      const page = await service.getStats(dto());
      const [view, click, open] = page.doors.bubble;

      expect(view.passRate).toBe(1);
      expect(click.passRate).toBeCloseTo(0.5); // 50/100 users, not 60/900
      expect(click.dropUsers).toBe(50);
      expect(open.passRate).toBeCloseTo(0.45);
    });
  });

  describe('the exit plea', () => {
    it('rates staying against the people who answered, not those who saw it', async () => {
      dashboard.eventTotals = jest.fn().mockResolvedValue(
        totalsOf({
          coach_exit_plea_view: { events: 100, users: 40 },
          coach_exit_stay: { events: 30, users: 20 },
          coach_exit_leave: { events: 60, users: 30 },
        }),
      );

      const page = await service.getStats(dto());

      // 30/90, not 30/100: a plea somebody swiped past proves nothing either way.
      expect(page.ending.plea.stayRate).toBeCloseTo(1 / 3);
    });
  });

  describe('turn failures', () => {
    it('rates failures against every attempt, sent or not', async () => {
      dashboard.eventTotals = jest.fn().mockResolvedValue(
        totalsOf({
          coach_turn_send: { events: 90, users: 30 },
          coach_turn_failed: { events: 10, users: 6 },
        }),
      );

      const page = await service.getStats(dto());

      expect(page.inSession.failureRate).toBeCloseTo(0.1); // 10/100
    });
  });

  describe('breakdowns', () => {
    it('labels known ids and passes unknown ones through raw', async () => {
      breakdown({
        'coach_scr_view|params.entry': [
          { id: 'home', events: 60, users: 30 },
          { id: 'lesson', events: 40, users: 25 },
          { id: 'something_new', events: 5, users: 5 },
        ],
      });

      const page = await service.getStats(dto());
      const labels = page.doors.byEntry.map((row) => row.label);

      expect(labels).toEqual(['Home', 'Cuối bài học', 'something_new']);
      expect(page.doors.byEntry[0].share).toBeCloseTo(60 / 105);
    });

    it('rates a truncated breakdown against the real total, not the rows shown', async () => {
      // 47 steps exist and the repository returns at most 30, so summing what
      // came back would make every share a fraction of the visible slice — the
      // rows would add up to 100% while describing part of the data.
      dashboard.eventTotals = jest.fn().mockResolvedValue(
        totalsOf({ coach_scr_exit: { events: 1000, users: 200 } }),
      );
      breakdown({
        'coach_scr_exit|params.step': [
          { id: 'story', events: 300, users: 100 },
          { id: 'intent', events: 100, users: 60 },
        ],
      });

      const page = await service.getStats(dto());

      expect(page.inSession.exitStep[0].share).toBeCloseTo(0.3); // 300/1000
      expect(page.inSession.exitStep[1].share).toBeCloseTo(0.1); // not 100/400
    });
  });

  describe('the comparison period', () => {
    it('ends before the current range starts, so no day is counted twice', async () => {
      await service.getStats(dto({ compare: true }));

      const ranges = (dashboard.eventTotals as jest.Mock).mock.calls.map(
        ([filter]) => filter,
      );
      expect(ranges).toHaveLength(2);

      const [current, previous] = ranges;
      expect(previous.to.getTime()).toBeLessThan(current.from.getTime());
      expect(previous.to.getTime() - previous.from.getTime()).toBe(
        current.to.getTime() - current.from.getTime(),
      );
    });

    it('leaves previous null when comparison is off', async () => {
      const page = await service.getStats(dto({ compare: false }));

      expect(page.compareRange).toBeNull();
      expect(page.ending.previous).toBeNull();
    });
  });

  describe('numeric distributions', () => {
    it('keeps completed and abandoned sessions apart', async () => {
      coach.numericStatsByOutcome = jest.fn(
        async (_filter: any, _event: string, valuePath: string) =>
          valuePath === 'params.duration_sec'
            ? {
                true: { count: 50, mean: 240, median: 210, p90: 480 },
                false: { count: 30, mean: 45, median: 30, p90: 120 },
              }
            : {},
      ) as any;

      const page = await service.getStats(dto());

      expect(page.ending.durationSec.completed.median).toBe(210);
      expect(page.ending.durationSec.abandoned.median).toBe(30);
      // turn_count had no rows at all — an absent outcome is empty, not zero-ish.
      expect(page.ending.turnCount.completed).toEqual(emptyStats);
    });
  });
});
