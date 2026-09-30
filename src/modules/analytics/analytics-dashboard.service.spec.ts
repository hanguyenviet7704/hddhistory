import { AnalyticsDashboardService } from './analytics-dashboard.service';
import { GetDashboardDto } from './dto/get-dashboard.dto';
import { AnalyticsDashboardRepository } from './repository/analytics-dashboard.repository';

/**
 * The arithmetic between the aggregations and the panel.
 *
 * The pipelines themselves are exercised against a real Mongo; what is easy to
 * get wrong up here is the interpretation — reporting 0% for something that was
 * never measured, or comparing against a period that overlaps the current one.
 */
describe('AnalyticsDashboardService', () => {
  let service: AnalyticsDashboardService;
  let repository: jest.Mocked<Partial<AnalyticsDashboardRepository>>;

  const dto = (overrides: Partial<GetDashboardDto> = {}): GetDashboardDto =>
    ({
      from: '2026-08-01T00:00:00.000Z',
      to: '2026-08-07T23:59:59.999Z',
      appEnv: 'prod',
      timezone: 'Asia/Ho_Chi_Minh',
      compare: true,
      ...overrides,
    }) as GetDashboardDto;

  // Constructed directly rather than through a Nest testing module: the module
  // graph adds nothing here, and the repo's other specs keep the same shape.
  const emptyDurations = {
    count: 0,
    medianMs: null,
    p25Ms: null,
    p75Ms: null,
    engagedMedianMs: null,
    longSessions: 0,
    bounces: 0,
  };

  beforeEach(() => {
    repository = {
      activityHeatmap: jest.fn().mockResolvedValue({ all: [], learning: [] }),
      countActiveUsers: jest.fn().mockResolvedValue(0),
      countActiveUsersInWindow: jest.fn().mockResolvedValue(0),
      countNewUsers: jest.fn().mockResolvedValue(0),
      dailyActiveUsers: jest.fn().mockResolvedValue([]),
      dailyActiveUsersByPlatform: jest.fn().mockResolvedValue([]),
      dailyNewUsers: jest.fn().mockResolvedValue([]),
      usersByDimension: jest.fn().mockResolvedValue([]),
      demographics: jest
        .fn()
        .mockResolvedValue({ byCountry: [], byAge: [] }),
      retentionCohorts: jest
        .fn()
        .mockResolvedValue({ overall: [], byAppVersion: [], byPlatform: [] }),
      sessionStats: jest.fn().mockResolvedValue({
        totals: {
          sessions: 0,
          engagedSessions: 0,
          totalDurationMs: 0,
          totalEvents: 0,
          totalScreens: 0,
          activeUsers: 0,
        },
        daily: [],
        depthBuckets: [],
        durations: emptyDurations,
        byWeekday: [],
        byAppVersion: [],
      }),
      hourlyActivity: jest.fn().mockResolvedValue([]),
      onboardingFunnel: jest
        .fn()
        .mockResolvedValue({ steps: [], started: 0, completed: 0 }),
      eventTotals: jest.fn().mockResolvedValue({}),
      eventTotalsByPlatform: jest.fn().mockResolvedValue({}),
      countScreenViews: jest.fn().mockResolvedValue(0),
      topContentByEvent: jest.fn().mockResolvedValue({}),
      contentByAge: jest.fn().mockResolvedValue({ rows: [], usersByAge: [] }),
      dailyEventUsers: jest.fn().mockResolvedValue([]),
      topContent: jest.fn().mockResolvedValue([]),
      versionDepth: jest.fn().mockResolvedValue([]),
    };

    service = new AnalyticsDashboardService(
      repository as unknown as AnalyticsDashboardRepository,
    );
  });

  describe('comparison period', () => {
    it('measures the preceding window of the same length without overlapping', async () => {
      await service.getUsers(dto());

      const calls = (repository.countActiveUsers as jest.Mock).mock.calls;
      const [current] = calls[0];
      const [previous] = calls[1];

      expect(previous.to.getTime()).toBe(current.from.getTime() - 1);
      expect(previous.to.getTime() - previous.from.getTime()).toBe(
        current.to.getTime() - current.from.getTime(),
      );
    });

    it('skips the previous period entirely when compare is off', async () => {
      const result = await service.getUsers(dto({ compare: false }));

      expect(result.compareRange).toBeNull();
      expect(result.previousTotals).toBeNull();
      expect(repository.countActiveUsers).toHaveBeenCalledTimes(1);
    });
  });

  describe('rates with no denominator', () => {
    it('reports a null completion rate rather than 0% when nobody started', async () => {
      const result = await service.getOnboarding(dto());

      expect(result.started).toBe(0);
      expect(result.completionRate).toBeNull();
    });

    it('reports a null retention rate for a cohort too young to measure', async () => {
      (repository.retentionCohorts as jest.Mock).mockResolvedValue({
        overall: [
          { offset: 1, cohortUsers: 40, retained: 10 },
          { offset: 7, cohortUsers: 0, retained: 0 },
        ],
        byAppVersion: [],
        byPlatform: [],
      });

      const result = await service.getUsers(dto());

      expect(result.retention[0].rate).toBeCloseTo(0.25);
      expect(result.retention[1].rate).toBeNull();
    });

    it('reports a null engagement rate when there were no sessions', async () => {
      const result = await service.getSessions(dto());

      expect(result.totals.engagementRate).toBeNull();
      expect(result.totals.sessionsPerUser).toBeNull();
    });
  });

  describe('rolling activity windows', () => {
    it('anchors DAU / WAU / MAU at the end of the range, not at today', async () => {
      const input = dto();
      await service.getUsers(input);

      const calls = (repository.countActiveUsersInWindow as jest.Mock).mock
        .calls;
      const spanDays = ([, from, to]: [unknown, Date, Date]) =>
        Math.round((to.getTime() - from.getTime()) / 86400000);

      // A report for last month must show last month's MAU.
      expect(calls[0][2].toISOString()).toBe(new Date(input.to!).toISOString());
      expect(spanDays(calls[0] as any)).toBe(1);
      expect(spanDays(calls[1] as any)).toBe(7);
      expect(spanDays(calls[2] as any)).toBe(28);
      // The "đầu kỳ" figure is the same 28-day window ending where the range
      // begins, which is what makes the growth badge meaningful.
      expect(calls[3][2].toISOString()).toBe(
        new Date(input.from!).toISOString(),
      );
      expect(spanDays(calls[3] as any)).toBe(28);
    });

    it('computes stickiness as DAU over MAU', async () => {
      (repository.countActiveUsersInWindow as jest.Mock)
        .mockResolvedValueOnce(200) // dau
        .mockResolvedValueOnce(776) // wau
        .mockResolvedValueOnce(1407) // mau
        .mockResolvedValueOnce(403); // mau at start

      const result = await service.getUsers(dto());

      expect(result.activeWindows.stickiness).toBeCloseTo(200 / 1407);
      expect(result.activeWindows.mauAtStart).toBe(403);
    });
  });

  describe('demographics', () => {
    it('flags an uncollected field instead of pretending the query was empty', async () => {
      const result = await service.getUsers(dto());

      expect(result.demographics.hasCountryData).toBe(false);
      expect(result.demographics.hasAgeData).toBe(false);
    });
  });

  describe('user totals', () => {
    it('never reports a negative returning count', async () => {
      // More signups than active users happens whenever someone registers and
      // never opens the app again in the period.
      (repository.countActiveUsers as jest.Mock).mockResolvedValue(10);
      (repository.countNewUsers as jest.Mock).mockResolvedValue(25);

      const result = await service.getUsers(dto());

      expect(result.totals.returning).toBe(0);
    });
  });

  describe('funnel', () => {
    beforeEach(() => {
      (repository.onboardingFunnel as jest.Mock).mockResolvedValue({
        started: 100,
        completed: 55,
        steps: [
          { event: 'obd_intro1_scr_view', users: 100 },
          { event: 'obd_welcome_scr_view', users: 80 },
          { event: 'obd_name_scr_view', users: 60 },
          { event: 'obd_complete_scr_view', users: 55 },
        ],
      });
    });

    it('measures pass rate against the first step and drop against the previous one', async () => {
      const result = await service.getOnboarding(dto());

      expect(result.steps[1].passRate).toBeCloseTo(0.8);
      expect(result.steps[1].dropUsers).toBe(20);
      expect(result.steps[1].dropRate).toBeCloseTo(0.2);
      // The first step has nobody before it to lose.
      expect(result.steps[0].dropRate).toBeNull();
    });

    it('names the step that loses the most people, never the first step', async () => {
      const result = await service.getOnboarding(dto());

      expect(result.biggestDrop?.event).toBe('obd_welcome_scr_view');
      expect(result.biggestDrop?.dropUsers).toBe(20);
    });
  });

  describe('session depth by app version', () => {
    const versionRow = (
      appVersion: string,
      overrides: Record<string, number> = {},
    ) => ({
      appVersion,
      sessions: 100,
      users: 50,
      completers: 25,
      activeDays: 10,
      completions: 60,
      medianMs: 120000,
      ...overrides,
    });

    it('orders versions numerically, not as strings', async () => {
      (repository.versionDepth as jest.Mock).mockResolvedValue([
        versionRow('1.4.10'),
        versionRow('1.4.9'),
        versionRow('1.4.2'),
      ]);

      const result = await service.getOverview(dto());

      // A plain string sort would put 1.4.10 before 1.4.2 and make the delta
      // compare the wrong pair of builds.
      expect(
        result.versionDepth.versions.map((row) => row.appVersion),
      ).toEqual(['1.4.2', '1.4.9', '1.4.10']);
      expect(result.versionDepth.deltas.from).toBe('1.4.2');
      expect(result.versionDepth.deltas.to).toBe('1.4.10');
    });

    it('reports a rate change in percentage points and the rest as percentages', async () => {
      (repository.versionDepth as jest.Mock).mockResolvedValue([
        versionRow('1.4.2', {
          medianMs: 126000,
          sessions: 100,
          completions: 60,
          users: 100,
          completers: 67,
          activeDays: 10,
        }),
        versionRow('1.4.4', {
          medianMs: 222000,
          sessions: 100,
          completions: 111,
          users: 100,
          completers: 80,
          activeDays: 10,
        }),
      ]);

      const result = await service.getOverview(dto());
      const { deltas, versions } = result.versionDepth;

      expect(versions[0].lessonsPerSession).toBeCloseTo(0.6);
      expect(versions[1].lessonsPerSession).toBeCloseTo(1.11);
      expect(deltas.lessonsPerSessionPct).toBeCloseTo(0.85);
      // 67% → 80% is +13 points, NOT +19%.
      expect(deltas.completionRatePoints).toBeCloseTo(0.13);
      expect(deltas.sessionDurationPct).toBeCloseTo((222000 - 126000) / 126000);
    });

    it('leaves the deltas null when only one version was seen', async () => {
      (repository.versionDepth as jest.Mock).mockResolvedValue([
        versionRow('1.4.4'),
      ]);

      const result = await service.getOverview(dto());

      expect(result.versionDepth.versions).toHaveLength(1);
      expect(result.versionDepth.deltas.sessionDurationPct).toBeNull();
      expect(result.versionDepth.deltas.to).toBeNull();
    });
  });

  describe('learning funnel', () => {
    it('measures every step against the first one', async () => {
      (repository.eventTotals as jest.Mock).mockResolvedValue({
        roadmap_scr_view: { users: 802, events: 5120 },
        keypoint_read_scr_view: { users: 680, events: 4010 },
        keypoint_complete_scr_view: { users: 514, events: 2038 },
      });

      const result = await service.getLearning(dto());

      expect(result.milestones[0].passRate).toBe(1);
      expect(result.milestones[1].passRate).toBeCloseTo(680 / 802);
      expect(result.milestones[2].passRate).toBeCloseTo(514 / 802);
      // Completions are events; the finishers are people. Both are reported
      // because "2.038 lượt bởi 514 người" is the sentence anyone wants.
      expect(result.engagement.keypointCompletions).toBe(2038);
      expect(result.engagement.keypointCompletionUsers).toBe(514);
    });

    it('groups the age tabs into an interested and a completed list', async () => {
      (repository.contentByAge as jest.Mock).mockResolvedValue({
        usersByAge: [{ name: '18-24', value: 297 }],
        rows: [
          {
            age: '18-24',
            event: 'keypoint_read_scr_view',
            name: 'Stop rereading',
            id: 'c1',
            users: 43,
          },
          {
            age: '18-24',
            event: 'keypoint_complete_scr_view',
            name: 'Read people like a book',
            id: 'c3',
            users: 28,
          },
          // A different age band must not leak into the 18-24 tab.
          {
            age: '25-34',
            event: 'keypoint_read_scr_view',
            name: 'Other course',
            id: 'c9',
            users: 5,
          },
        ],
      });

      const result = await service.getLearning(dto());

      expect(result.byAge).toHaveLength(1);
      expect(result.byAge[0].users).toBe(297);
      expect(result.byAge[0].interested.map((row) => row.name)).toEqual([
        'Stop rereading',
      ]);
      expect(result.byAge[0].completed.map((row) => row.name)).toEqual([
        'Read people like a book',
      ]);
    });
  });

  describe('session averages', () => {
    it('derives per-session averages from the totals', async () => {
      (repository.sessionStats as jest.Mock).mockResolvedValue({
        totals: {
          sessions: 4,
          engagedSessions: 3,
          totalDurationMs: 120000,
          totalEvents: 50,
          totalScreens: 20,
          activeUsers: 2,
        },
        daily: [],
        depthBuckets: [],
        durations: emptyDurations,
        byWeekday: [],
        byAppVersion: [],
      });

      const result = await service.getSessions(dto());

      expect(result.totals.engagementRate).toBeCloseTo(0.75);
      expect(result.totals.avgDurationMs).toBe(30000);
      expect(result.totals.avgEvents).toBe(12.5);
      expect(result.totals.sessionsPerUser).toBe(2);
    });

    it('turns long-session and bounce counts into shares of all sessions', async () => {
      (repository.sessionStats as jest.Mock).mockResolvedValue({
        totals: {
          sessions: 8,
          engagedSessions: 5,
          totalDurationMs: 0,
          totalEvents: 0,
          totalScreens: 0,
          activeUsers: 4,
        },
        daily: [],
        depthBuckets: [],
        durations: {
          count: 8,
          medianMs: 30000,
          p25Ms: 10000,
          p75Ms: 50000,
          engagedMedianMs: 40000,
          longSessions: 1,
          bounces: 3,
        },
        byWeekday: [],
        byAppVersion: [],
      });

      const result = await service.getSessions(dto());

      expect(result.durations.longSessionRate).toBeCloseTo(0.125);
      expect(result.durations.bounceRate).toBeCloseTo(0.375);
      // Percentiles pass through untouched — they are the repository's answer.
      expect(result.durations.medianMs).toBe(30000);
      expect(result.durations.p75Ms).toBe(50000);
    });

    it('leaves the duration shares null when there were no sessions at all', async () => {
      const result = await service.getSessions(dto());

      expect(result.durations.longSessionRate).toBeNull();
      expect(result.durations.bounceRate).toBeNull();
      expect(result.durations.medianMs).toBeNull();
    });
  });
});
