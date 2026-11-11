import { StudyJournalService } from './study-journal.service';

/**
 * The journal's whole correctness lives in two places: the timezone arithmetic
 * that decides which UTC instants belong to a local day, and the thresholds
 * that turn a count into a shade. Both are silent when wrong — the calendar
 * still renders, just against the wrong days — so they are pinned here.
 */
function makeService(opts: { userId?: string } = {}) {
  const repository: any = {
    countKeypointsPerDay: jest.fn().mockResolvedValue([]),
    findFirstSubmissionAt: jest.fn().mockResolvedValue(null),
    findItemsInWindow: jest.fn().mockResolvedValue([]),
  };
  const habitRepository: any = {
    findDoneOnDate: jest.fn().mockResolvedValue([]),
  };
  const requestService: any = {
    user: { id: opts.userId ?? 'user-1' },
  };

  return {
    service: new StudyJournalService(repository, habitRepository, requestService),
    repository,
    habitRepository,
  };
}

describe('StudyJournalService.getMonth', () => {
  it('asks for the month in the caller local time, not the server day', async () => {
    const { service, repository } = makeService();

    await service.getMonth({ month: '2026-08', tzOffset: 420 });

    const [args] = repository.countKeypointsPerDay.mock.calls[0];
    // 1 Aug 00:00 in UTC+7 is 31 Jul 17:00 UTC — the hours a naive UTC window
    // would file under the previous month.
    expect(args.fromUtc.toISOString()).toBe('2026-07-31T17:00:00.000Z');
    expect(args.toUtc.toISOString()).toBe('2026-08-31T17:00:00.000Z');
    expect(args.tzOffsetString).toBe('+07:00');
  });

  it('handles a negative offset and a year boundary', async () => {
    const { service, repository } = makeService();

    await service.getMonth({ month: '2026-12', tzOffset: -300 });

    const [args] = repository.countKeypointsPerDay.mock.calls[0];
    expect(args.fromUtc.toISOString()).toBe('2026-12-01T05:00:00.000Z');
    expect(args.toUtc.toISOString()).toBe('2027-01-01T05:00:00.000Z');
    expect(args.tzOffsetString).toBe('-05:00');
  });

  it('maps keypoint counts onto the four legend shades', async () => {
    const { service, repository } = makeService();
    repository.countKeypointsPerDay.mockResolvedValue([
      { date: '2026-08-01', keypoints: 1 },
      { date: '2026-08-02', keypoints: 3 },
      { date: '2026-08-03', keypoints: 5 },
      { date: '2026-08-04', keypoints: 12 },
    ]);

    const result = await service.getMonth({ month: '2026-08', tzOffset: 420 });

    expect(result.days.map(day => day.level)).toEqual([1, 2, 3, 4]);
    expect(result.summary).toEqual({ activeDays: 4, keypoints: 21 });
  });

  it('reports the first active day in the caller own calendar', async () => {
    const { service, repository } = makeService();
    // 22:30 UTC is already the next day in Hanoi; reporting the UTC date would
    // let the calendar page back to a month with nothing in it.
    repository.findFirstSubmissionAt.mockResolvedValue(
      new Date('2026-03-31T22:30:00.000Z'),
    );

    const result = await service.getMonth({ month: '2026-08', tzOffset: 420 });

    expect(result.firstActiveDate).toBe('2026-04-01');
  });

  it('reports no first active day for a learner who has never studied', async () => {
    const { service } = makeService();

    const result = await service.getMonth({ month: '2026-08', tzOffset: 420 });

    expect(result.firstActiveDate).toBeNull();
    expect(result.days).toEqual([]);
  });
});

describe('StudyJournalService.getDay', () => {
  it('windows exactly one local day', async () => {
    const { service, repository } = makeService();

    await service.getDay({ date: '2026-08-19', tzOffset: 420 });

    const [args] = repository.findItemsInWindow.mock.calls[0];
    expect(args.fromUtc.toISOString()).toBe('2026-08-18T17:00:00.000Z');
    expect(args.toUtc.toISOString()).toBe('2026-08-19T17:00:00.000Z');
  });

  it('addresses habit check-ins by their date-only UTC midnight, not the shifted window', async () => {
    const { service, habitRepository } = makeService();

    await service.getDay({ date: '2026-08-19', tzOffset: 420 });

    const [args] = habitRepository.findDoneOnDate.mock.calls[0];
    // `habit_checkins.date` is normalised to UTC midnight of the LOCAL day, so
    // shifting it by the offset the keypoint window uses would look for a row
    // that cannot exist and drop every habit from the sheet.
    expect(args.dateOnlyUtc.toISOString()).toBe('2026-08-19T00:00:00.000Z');
  });

  it('sums the day minutes off the keypoints and counts both sections', async () => {
    const { service, repository, habitRepository } = makeService();
    repository.findItemsInWindow.mockResolvedValue([
      {
        courseId: 'c1',
        courseTitle: { en: 'The art of listening' },
        image: 'https://cdn/x.png',
        lessonId: 'l1',
        lessonTitle: { en: 'Lesson' },
        keypointId: 'k1',
        keypointTitle: { en: 'Listen to understand' },
        minutes: 9,
        passed: true,
        submittedAt: new Date('2026-08-19T03:00:00.000Z'),
      },
      {
        courseId: 'c1',
        courseTitle: { en: 'The art of listening' },
        image: '',
        lessonId: 'l2',
        lessonTitle: { en: 'Protect your attention' },
        keypointId: 'k2',
        keypointTitle: {},
        minutes: 7,
        passed: false,
        submittedAt: new Date('2026-08-19T04:00:00.000Z'),
      },
    ]);
    habitRepository.findDoneOnDate.mockResolvedValue([
      { userHabitId: 'uh1', habitId: 'h1', title: { en: 'Evening reflection' } },
    ]);

    const result = await service.getDay({ date: '2026-08-19', tzOffset: 420 });

    expect(result.summary).toEqual({ lessons: 2, minutes: 16, habits: 1 });
    // Two keypoints of ONE course collapse into a single row carrying both the
    // count and the summed minutes.
    expect(result.courses).toEqual([
      {
        courseId: 'c1',
        title: 'The art of listening',
        image: 'https://cdn/x.png',
        lessons: 2,
        minutes: 16,
      },
    ]);
    expect(result.habits[0].title).toBe('Evening reflection');
  });

  it('rolls over the month end without special-casing it', async () => {
    const { service, repository } = makeService();

    await service.getDay({ date: '2026-08-31', tzOffset: 0 });

    const [args] = repository.findItemsInWindow.mock.calls[0];
    expect(args.toUtc.toISOString()).toBe('2026-09-01T00:00:00.000Z');
  });
});
