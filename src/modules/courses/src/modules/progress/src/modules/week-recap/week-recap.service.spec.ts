import { longestRun, previousWeekBounds, weekBounds } from './week-recap.helper';
import { WeekRecapService } from './week-recap.service';

/**
 * Two things here are silent when wrong, so both are pinned.
 *
 * The week arithmetic decides WHICH seven days a poster is cut from — get it
 * wrong and every number is still plausible, just about the wrong week. And the
 * two day conventions (keypoint timestamps are shifted by the offset, habit
 * check-ins are bare UTC midnights) are exactly the kind of mix-up that files a
 * habit one day away from the keypoint it was done beside.
 */
function makeService(opts: { userId?: string; existing?: any } = {}) {
  const weekRecapRepository: any = {
    findForWeek: jest.fn().mockResolvedValue(opts.existing ?? null),
    findOwnedById: jest.fn().mockResolvedValue(null),
    createIfAbsent: jest.fn().mockImplementation(async (data: any) => ({
      ...data,
      _id: 'recap-1',
    })),
    replaceUnseen: jest.fn().mockImplementation(async ({ data }: any) => ({
      ...data,
      _id: 'recap-1',
    })),
    findArchive: jest.fn().mockResolvedValue([]),
    countArchive: jest.fn().mockResolvedValue(0),
    nextWeekNumber: jest.fn().mockResolvedValue(1),
    stampViewed: jest.fn().mockResolvedValue(undefined),
    stampDismissed: jest.fn().mockResolvedValue(undefined),
  };
  const habitRepository: any = {
    findInRange: jest.fn().mockResolvedValue([]),
  };
  const studyJournalRepository: any = {
    findItemsInWindow: jest.fn().mockResolvedValue([]),
  };
  const requestService: any = { user: { id: opts.userId ?? 'user-1' } };

  return {
    service: new WeekRecapService(
      weekRecapRepository,
      habitRepository,
      studyJournalRepository,
      requestService,
    ),
    weekRecapRepository,
    habitRepository,
    studyJournalRepository,
  };
}

function keypoint(submittedAt: string, over: Record<string, any> = {}) {
  return {
    courseId: 'course-a',
    courseTitle: { en: 'Course A' },
    image: 'a.png',
    lessonId: 'lesson-a',
    lessonTitle: { en: 'Lesson A' },
    keypointId: 'kp',
    keypointTitle: { en: 'KP' },
    minutes: 7,
    passed: true,
    submittedAt: new Date(submittedAt),
    ...over,
  };
}

describe('previousWeekBounds', () => {
  it('cuts the Monday-to-Sunday week before the caller own week', () => {
    // Thursday 20 Aug 2026, 09:00 in UTC+7.
    const bounds = previousWeekBounds(new Date('2026-08-20T02:00:00.000Z'), 420);

    expect(bounds.dates).toEqual([
      '2026-08-10',
      '2026-08-11',
      '2026-08-12',
      '2026-08-13',
      '2026-08-14',
      '2026-08-15',
      '2026-08-16',
    ]);
    // Local Monday 00:00 in UTC+7 is the previous day at 17:00 UTC — the hours
    // a naive UTC cut would hand to the wrong week.
    expect(bounds.weekStart.toISOString()).toBe('2026-08-09T17:00:00.000Z');
    expect(bounds.weekEnd.toISOString()).toBe('2026-08-16T17:00:00.000Z');
    // Habit check-ins are matched as bare dates, with no offset applied.
    expect(bounds.dateOnlyFrom.toISOString()).toBe('2026-08-10T00:00:00.000Z');
    expect(bounds.dateOnlyTo.toISOString()).toBe('2026-08-17T00:00:00.000Z');
  });

  it('treats Sunday as the end of a week, not the start of one', () => {
    // Sunday 16 Aug 2026 in UTC. Sunday-based indexing would call this the
    // first day of a week and hand back the wrong seven days.
    const bounds = previousWeekBounds(new Date('2026-08-16T12:00:00.000Z'), 0);

    expect(bounds.dates[0]).toBe('2026-08-03');
    expect(bounds.dates[6]).toBe('2026-08-09');
  });

  it('walks back across a month and a year boundary', () => {
    // Tuesday 5 Jan 2027, so last week straddles New Year.
    const bounds = previousWeekBounds(new Date('2027-01-05T12:00:00.000Z'), 0);

    expect(bounds.dates[0]).toBe('2026-12-28');
    expect(bounds.dates[6]).toBe('2027-01-03');
  });

  it('cuts the week by the caller offset, not the host one', () => {
    // 03:00 Monday UTC is still Sunday evening in UTC-5, so that caller's
    // "last week" is one week earlier than the UTC caller's.
    const utc = previousWeekBounds(new Date('2026-08-17T03:00:00.000Z'), 0);
    const newYork = previousWeekBounds(new Date('2026-08-17T03:00:00.000Z'), -300);

    expect(utc.dates[0]).toBe('2026-08-10');
    expect(newYork.dates[0]).toBe('2026-08-03');
  });
});

describe('longestRun', () => {
  it('counts the longest unbroken run, not the total', () => {
    expect(longestRun([true, true, false, true, true, true, false])).toBe(3);
  });

  it('is zero for a week with nothing in it', () => {
    expect(longestRun([false, false, false, false, false, false, false])).toBe(0);
  });

  it('handles a run that ends on the last day', () => {
    expect(longestRun([false, true, true, true, true, true, true])).toBe(6);
  });
});

describe('WeekRecapService.getCurrent', () => {
  it('asks both sources for the same week, each in its own day convention', async () => {
    const { service, studyJournalRepository, habitRepository } = makeService();
    jest.useFakeTimers().setSystemTime(new Date('2026-08-20T02:00:00.000Z'));

    await service.getCurrent({ tzOffset: 420 });

    const [progressArgs] = studyJournalRepository.findItemsInWindow.mock.calls[0];
    expect(progressArgs.fromUtc.toISOString()).toBe('2026-08-09T17:00:00.000Z');

    const [habitArgs] = habitRepository.findInRange.mock.calls[0];
    expect(habitArgs.dateOnlyFrom.toISOString()).toBe('2026-08-10T00:00:00.000Z');

    jest.useRealTimers();
  });

  it('gives no recap for a week nobody showed up for, and burns no week number', async () => {
    const { service, weekRecapRepository } = makeService();
    jest.useFakeTimers().setSystemTime(new Date('2026-08-20T02:00:00.000Z'));

    const result = await service.getCurrent({ tzOffset: 420 });

    expect(result.recap).toBeNull();
    const [written] = weekRecapRepository.createIfAbsent.mock.calls[0];
    // The row still exists, so the aggregation does not run again on every
    // app open — it is just never shown.
    expect(written.hasActivity).toBe(false);
    expect(written.weekNumber).toBe(0);
    expect(weekRecapRepository.nextWeekNumber).not.toHaveBeenCalled();

    jest.useRealTimers();
  });

  it('counts the streak inside the week, not the days total', async () => {
    const { service, weekRecapRepository, studyJournalRepository } = makeService();
    jest.useFakeTimers().setSystemTime(new Date('2026-08-20T02:00:00.000Z'));
    // Mon-Sat studied, Sunday off — six consecutive days, which is what the
    // artwork's "CHUỖI" stamp shows beside a calendar row of the same shape.
    studyJournalRepository.findItemsInWindow.mockResolvedValue([
      keypoint('2026-08-09T17:30:00.000Z'),
      keypoint('2026-08-10T17:30:00.000Z'),
      keypoint('2026-08-11T17:30:00.000Z'),
      keypoint('2026-08-12T17:30:00.000Z'),
      keypoint('2026-08-13T17:30:00.000Z'),
      keypoint('2026-08-14T17:30:00.000Z'),
    ]);

    const result = await service.getCurrent({ tzOffset: 420 });

    expect(result.recap?.stats.activeDays).toBe(6);
    expect(result.recap?.stats.streakDays).toBe(6);
    expect(result.recap?.stats.keypoints).toBe(6);
    expect(result.recap?.stats.minutes).toBe(42);
    expect(result.recap?.days.map(day => day.active)).toEqual([
      true, true, true, true, true, true, false,
    ]);
    expect(weekRecapRepository.nextWeekNumber).toHaveBeenCalled();

    jest.useRealTimers();
  });

  it('lands a habit mood on the day it was filed, and keeps the latest one', async () => {
    const { service, habitRepository } = makeService();
    jest.useFakeTimers().setSystemTime(new Date('2026-08-20T02:00:00.000Z'));
    habitRepository.findInRange.mockResolvedValue([
      {
        date: new Date('2026-08-12T00:00:00.000Z'),
        done: true,
        mood: 1,
        habitId: 'h1',
        title: { en: 'Breathe' },
      },
      {
        date: new Date('2026-08-12T00:00:00.000Z'),
        done: true,
        mood: 3,
        habitId: 'h2',
        title: { en: 'Journal' },
      },
    ]);

    const result = await service.getCurrent({ tzOffset: 420 });

    // 12 Aug is the third cell of a week starting on the 10th.
    expect(result.recap?.days[2].date).toBe('2026-08-12');
    expect(result.recap?.days[2].mood).toBe(3);
    expect(result.recap?.days[2].active).toBe(true);
    expect(result.recap?.stats.habitsKept).toBe(2);
    expect(result.recap?.days[0].mood).toBeNull();

    jest.useRealTimers();
  });

  it('counts a journal-only day as showing up but not as a habit kept', async () => {
    const { service, habitRepository } = makeService();
    jest.useFakeTimers().setSystemTime(new Date('2026-08-20T02:00:00.000Z'));
    habitRepository.findInRange.mockResolvedValue([
      {
        date: new Date('2026-08-10T00:00:00.000Z'),
        done: false,
        mood: 2,
        habitId: 'h1',
        title: { en: 'Breathe' },
      },
    ]);

    const result = await service.getCurrent({ tzOffset: 420 });

    expect(result.recap?.stats.activeDays).toBe(1);
    expect(result.recap?.stats.habitsKept).toBe(0);

    jest.useRealTimers();
  });

  it('keeps the three most recent distinct lessons, newest first', async () => {
    const { service, studyJournalRepository } = makeService();
    jest.useFakeTimers().setSystemTime(new Date('2026-08-20T02:00:00.000Z'));
    // Oldest first, as the repository returns them, with lesson-b studied twice.
    studyJournalRepository.findItemsInWindow.mockResolvedValue([
      keypoint('2026-08-09T17:30:00.000Z', { lessonId: 'lesson-a' }),
      keypoint('2026-08-10T17:30:00.000Z', { lessonId: 'lesson-b' }),
      keypoint('2026-08-11T17:30:00.000Z', { lessonId: 'lesson-b' }),
      keypoint('2026-08-12T17:30:00.000Z', { lessonId: 'lesson-c' }),
      keypoint('2026-08-13T17:30:00.000Z', { lessonId: 'lesson-d' }),
    ]);

    const result = await service.getCurrent({ tzOffset: 420 });

    expect(result.recap?.lessons.map(lesson => lesson.lessonId)).toEqual([
      'lesson-d',
      'lesson-c',
      'lesson-b',
    ]);

    jest.useRealTimers();
  });

  it('picks the favourite course by keypoints, breaking ties on minutes', async () => {
    const { service, studyJournalRepository } = makeService();
    jest.useFakeTimers().setSystemTime(new Date('2026-08-20T02:00:00.000Z'));
    studyJournalRepository.findItemsInWindow.mockResolvedValue([
      keypoint('2026-08-10T17:30:00.000Z', { courseId: 'quiet', minutes: 30, courseTitle: { en: 'Quiet' } }),
      keypoint('2026-08-11T17:30:00.000Z', { courseId: 'loud', minutes: 5, courseTitle: { en: 'Loud' } }),
      keypoint('2026-08-12T17:30:00.000Z', { courseId: 'loud', minutes: 5, courseTitle: { en: 'Loud' } }),
    ]);

    const result = await service.getCurrent({ tzOffset: 420 });

    expect(result.recap?.favouriteCourse?.courseId).toBe('loud');

    jest.useRealTimers();
  });

  it('does not touch a stored week once the rebuild window has closed', async () => {
    const existing = {
      _id: 'recap-9',
      weekNumber: 4,
      weekStart: new Date('2026-08-09T17:00:00.000Z'),
      weekEnd: new Date('2026-08-16T17:00:00.000Z'),
      tzOffset: 420,
      hasActivity: true,
      stats: { activeDays: 3, streakDays: 2, habitsKept: 1, keypoints: 5, minutes: 35 },
      days: [],
      lessons: [],
      habits: [],
    };
    const { service, weekRecapRepository, studyJournalRepository } = makeService({ existing });
    jest.useFakeTimers().setSystemTime(new Date('2026-08-20T02:00:00.000Z'));

    const result = await service.getCurrent({ tzOffset: 420 });

    expect(result.recap?.weekNumber).toBe(4);
    expect(studyJournalRepository.findItemsInWindow).not.toHaveBeenCalled();
    expect(weekRecapRepository.createIfAbsent).not.toHaveBeenCalled();

    jest.useRealTimers();
  });
});

describe('weekBounds', () => {
  it('reads the week still in progress when asked for weeksAgo 0', () => {
    // Thursday 20 Aug 2026 in UTC+7 — the current week runs 17-23 Aug.
    const bounds = weekBounds(new Date('2026-08-20T02:00:00.000Z'), 420, 0);

    expect(bounds.dates[0]).toBe('2026-08-17');
    expect(bounds.dates[6]).toBe('2026-08-23');
  });

  it('defaults to the finished week', () => {
    const now = new Date('2026-08-20T02:00:00.000Z');
    expect(weekBounds(now, 420).dates).toEqual(previousWeekBounds(now, 420).dates);
  });
});

describe('WeekRecapService.getCurrent — in-progress preview', () => {
  it('never stores the unfinished week, and previews the number Monday will assign', async () => {
    const { service, weekRecapRepository, studyJournalRepository } = makeService();
    jest.useFakeTimers().setSystemTime(new Date('2026-08-20T02:00:00.000Z'));
    studyJournalRepository.findItemsInWindow.mockResolvedValue([
      keypoint('2026-08-17T17:30:00.000Z'),
    ]);

    const result = await service.getCurrent({ tzOffset: 420, weekOffset: 0 });

    expect(result.recap?.stats.keypoints).toBe(1);
    // archiveCount is 0 in this mock, so Monday would assign week 1.
    expect(result.recap?.weekNumber).toBe(1);
    // Storing it would hand an unfinished week a slot in Sổ tay that the real
    // Monday recap then collides with.
    expect(weekRecapRepository.createIfAbsent).not.toHaveBeenCalled();
    expect(weekRecapRepository.replaceUnseen).not.toHaveBeenCalled();

    jest.useRealTimers();
  });

  it('reads the current week window, not last week', async () => {
    const { service, studyJournalRepository } = makeService();
    jest.useFakeTimers().setSystemTime(new Date('2026-08-20T02:00:00.000Z'));

    await service.getCurrent({ tzOffset: 420, weekOffset: 0 });

    const [args] = studyJournalRepository.findItemsInWindow.mock.calls[0];
    expect(args.fromUtc.toISOString()).toBe('2026-08-16T17:00:00.000Z');

    jest.useRealTimers();
  });
});

describe('WeekRecapService.getCurrent — rebuilding an unseen recap', () => {
  function stored(over: Record<string, any> = {}) {
    return {
      _id: 'recap-9',
      weekNumber: 4,
      weekStart: new Date('2026-08-09T17:00:00.000Z'),
      weekEnd: new Date('2026-08-16T17:00:00.000Z'),
      tzOffset: 420,
      hasActivity: true,
      stats: { activeDays: 1, streakDays: 1, habitsKept: 0, keypoints: 1, minutes: 7 },
      days: [],
      lessons: [],
      habits: [],
      ...over,
    };
  }

  it('recomputes a recap the learner has not been shown, picking up late data', async () => {
    const { service, weekRecapRepository, studyJournalRepository } = makeService({
      existing: stored(),
    });
    jest.useFakeTimers().setSystemTime(new Date('2026-08-18T02:00:00.000Z'));
    studyJournalRepository.findItemsInWindow.mockResolvedValue([
      keypoint('2026-08-09T17:30:00.000Z'),
      keypoint('2026-08-10T17:30:00.000Z'),
    ]);

    const result = await service.getCurrent({ tzOffset: 420 });

    expect(weekRecapRepository.replaceUnseen).toHaveBeenCalled();
    expect(result.recap?.stats.keypoints).toBe(2);
    // A rebuild must never renumber a poster.
    expect(result.recap?.weekNumber).toBe(4);

    jest.useRealTimers();
  });

  it('leaves a recap alone once the learner has opened it', async () => {
    const { service, weekRecapRepository, studyJournalRepository } = makeService({
      existing: stored({ viewedAt: new Date('2026-08-17T09:00:00.000Z') }),
    });
    jest.useFakeTimers().setSystemTime(new Date('2026-08-18T02:00:00.000Z'));

    await service.getCurrent({ tzOffset: 420 });

    // Numbers the reader has seen — and may already have shared — must not move.
    expect(studyJournalRepository.findItemsInWindow).not.toHaveBeenCalled();
    expect(weekRecapRepository.replaceUnseen).not.toHaveBeenCalled();

    jest.useRealTimers();
  });

  it('leaves a recap alone once "later" was chosen, not only once opened', async () => {
    const { service, weekRecapRepository } = makeService({
      existing: stored({ dismissedAt: new Date('2026-08-17T09:00:00.000Z') }),
    });
    jest.useFakeTimers().setSystemTime(new Date('2026-08-18T02:00:00.000Z'));

    await service.getCurrent({ tzOffset: 420 });

    expect(weekRecapRepository.replaceUnseen).not.toHaveBeenCalled();

    jest.useRealTimers();
  });

  it('freezes the snapshot once the rebuild window has passed', async () => {
    const { service, weekRecapRepository } = makeService({ existing: stored() });
    // Four days after the week closed: past the window, so a quiet week stops
    // re-aggregating on every app open for the rest of time.
    jest.useFakeTimers().setSystemTime(new Date('2026-08-20T18:00:00.000Z'));

    await service.getCurrent({ tzOffset: 420 });

    expect(weekRecapRepository.replaceUnseen).not.toHaveBeenCalled();

    jest.useRealTimers();
  });

  it('gives a week first cut as quiet its number once activity turns up', async () => {
    const { service, weekRecapRepository, studyJournalRepository } = makeService({
      existing: stored({ hasActivity: false, weekNumber: 0 }),
    });
    jest.useFakeTimers().setSystemTime(new Date('2026-08-18T02:00:00.000Z'));
    studyJournalRepository.findItemsInWindow.mockResolvedValue([
      keypoint('2026-08-11T17:30:00.000Z'),
    ]);
    weekRecapRepository.nextWeekNumber.mockResolvedValue(2);

    const result = await service.getCurrent({ tzOffset: 420 });

    expect(result.recap?.weekNumber).toBe(2);

    jest.useRealTimers();
  });
});

describe('WeekRecapService.markInteracted', () => {
  const stored = {
    _id: 'recap-9',
    weekNumber: 1,
    weekStart: new Date('2026-08-09T17:00:00.000Z'),
    weekEnd: new Date('2026-08-16T17:00:00.000Z'),
    tzOffset: 420,
    hasActivity: true,
    stats: { activeDays: 1, streakDays: 1, habitsKept: 0, keypoints: 1, minutes: 7 },
    days: [],
    lessons: [],
    habits: [],
  };

  it('routes viewing to the once-only stamp', async () => {
    const { service, weekRecapRepository } = makeService();
    weekRecapRepository.findOwnedById.mockResolvedValue(stored);

    await service.markInteracted('recap-9', 'viewedAt');

    expect(weekRecapRepository.stampViewed).toHaveBeenCalled();
    expect(weekRecapRepository.stampDismissed).not.toHaveBeenCalled();
  });

  it('routes "later" to the movable stamp — it must re-arm tomorrow', async () => {
    const { service, weekRecapRepository } = makeService();
    weekRecapRepository.findOwnedById.mockResolvedValue(stored);

    await service.markInteracted('recap-9', 'dismissedAt');

    expect(weekRecapRepository.stampDismissed).toHaveBeenCalled();
    expect(weekRecapRepository.stampViewed).not.toHaveBeenCalled();
  });
});
