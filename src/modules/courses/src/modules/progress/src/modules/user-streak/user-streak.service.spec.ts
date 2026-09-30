import { LessonType } from 'src/modules/courses/src/modules/lesson/enum/lesson.enum';
import { GradeResultType } from 'src/modules/courses/src/modules/progress/src/modules/user-progress/enum/user-progress.enum';

import {
  getDayDiff,
  getWeekContext,
  inferLastCompletedDate,
  normalizeTimezoneOffset,
} from './user-streak.helper';
import { UserStreakService } from './user-streak.service';

const VIETNAM_OFFSET_MINUTES = 420;
const USER_ID = 'user-1';

interface MakeServiceOptions {
  existingStreak?: Record<string, any> | null;
  timezoneOffsetHeader?: string;
  keypointMinutes?: number;
}

function makeService(opts: MakeServiceOptions = {}) {
  const stored =
    'existingStreak' in opts
      ? opts.existingStreak
      : {
          userId: USER_ID,
          weekStartDate: new Date(Date.UTC(2026, 6, 27)),
          weekStudy: [false, false, false, false, false, false, false],
          studyTime: 0,
          currentStreak: 0,
          bestStreak: 0,
        };

  const userStreakRepository: any = {
    findOne: jest.fn().mockResolvedValue(stored),
    create: jest.fn().mockImplementation((doc: any) => Promise.resolve(doc)),
    updateOne: jest.fn().mockResolvedValue(undefined),
  };
  const lessonModel: any = {
    findOne: jest.fn().mockReturnValue({
      lean: jest.fn().mockResolvedValue({ estimateCompleTimeNumber: 5 }),
    }),
  };
  const keypointModel: any = {
    find: jest.fn().mockReturnValue({
      lean: jest
        .fn()
        .mockResolvedValue([
          { estimateCompleTimeNumber: opts.keypointMinutes ?? 7 },
        ]),
    }),
  };
  const requestService: any = {
    user: { id: USER_ID },
    headers: {
      'x-timezone-offset':
        opts.timezoneOffsetHeader ?? String(VIETNAM_OFFSET_MINUTES),
    },
  };

  const service = new UserStreakService(
    userStreakRepository,
    lessonModel,
    keypointModel,
    requestService,
  );

  return { service, userStreakRepository };
}

describe('user-streak.helper day math', () => {
  it('files a Vietnam small-hours instant under the local day, not the UTC one', () => {
    // 00:30 Friday 31 July in Vietnam is still Thursday 17:30 UTC. The server
    // runs UTC, so before this fix the study day landed on Thursday.
    const instant = new Date('2026-07-30T17:30:00.000Z');

    const utc = getWeekContext(instant, 0);
    const local = getWeekContext(instant, VIETNAM_OFFSET_MINUTES);

    expect(utc.weekDayIndex).toBe(3); // Thursday
    expect(local.weekDayIndex).toBe(4); // Friday
    expect(local.todayStart.toISOString()).toBe('2026-07-31T00:00:00.000Z');
    expect(local.weekStartDate.toISOString()).toBe('2026-07-27T00:00:00.000Z');
  });

  it('keeps a negative offset on the earlier local day', () => {
    // 01:00 UTC Friday is still Thursday 20:00 in New York (UTC-5).
    const instant = new Date('2026-07-31T01:00:00.000Z');

    const local = getWeekContext(instant, -300);

    expect(local.weekDayIndex).toBe(3); // Thursday
    expect(local.todayStart.toISOString()).toBe('2026-07-30T00:00:00.000Z');
  });

  it('rolls the week start back across a month boundary', () => {
    // Wednesday 1 July 2026 -> the week began Monday 29 June.
    const local = getWeekContext(
      new Date('2026-07-01T03:00:00.000Z'),
      VIETNAM_OFFSET_MINUTES,
    );

    expect(local.weekStartDate.toISOString()).toBe('2026-06-29T00:00:00.000Z');
  });

  it('counts whole days between floating days regardless of server timezone', () => {
    const later = new Date(Date.UTC(2026, 6, 31));
    const earlier = new Date(Date.UTC(2026, 6, 29));

    expect(getDayDiff(later, earlier)).toBe(2);
    expect(getDayDiff(earlier, later)).toBe(-2);
    expect(getDayDiff(later, later)).toBe(0);
  });

  it('derives the last completed day from the week strip', () => {
    const weekStart = new Date(Date.UTC(2026, 6, 27)); // Monday
    const weekStudy = [false, false, true, true, false, false, false];

    expect(inferLastCompletedDate(weekStart, weekStudy)?.toISOString()).toBe(
      '2026-07-30T00:00:00.000Z', // Thursday
    );
    expect(inferLastCompletedDate(weekStart, [])).toBeNull();
  });

  it('falls back to UTC for a missing or unusable offset header', () => {
    expect(normalizeTimezoneOffset(undefined)).toBe(0);
    expect(normalizeTimezoneOffset('')).toBe(0);
    expect(normalizeTimezoneOffset('not-a-number')).toBe(0);
    expect(normalizeTimezoneOffset('99999')).toBe(0); // outside UTC-12..UTC+14
    expect(normalizeTimezoneOffset('-99999')).toBe(0);
    expect(normalizeTimezoneOffset('420')).toBe(VIETNAM_OFFSET_MINUTES);
    expect(normalizeTimezoneOffset(['420'])).toBe(VIETNAM_OFFSET_MINUTES);
    expect(normalizeTimezoneOffset(-300)).toBe(-300);
  });
});

describe('UserStreakService.markPresence', () => {
  beforeEach(() => {
    jest.useFakeTimers().setSystemTime(new Date('2026-07-31T01:00:00.000Z'));
  });

  afterEach(() => {
    jest.useRealTimers();
  });

  it('ticks today and starts the streak at 1 when nothing was studied yet', async () => {
    const { service, userStreakRepository } = makeService();

    const result = await service.markPresence(USER_ID);

    // 01:00 UTC + 7h = Friday in Vietnam -> index 4.
    expect(result.weekStudy).toEqual([
      false,
      false,
      false,
      false,
      true,
      false,
      false,
    ]);
    expect(result.currentStreak).toBe(1);
    expect(result.bestStreak).toBe(1);
    expect(userStreakRepository.updateOne).toHaveBeenCalledTimes(1);
  });

  it('extends the streak when yesterday was studied', async () => {
    const { service } = makeService({
      existingStreak: {
        userId: USER_ID,
        weekStartDate: new Date(Date.UTC(2026, 6, 27)),
        // Thursday only.
        weekStudy: [false, false, false, true, false, false, false],
        studyTime: 30,
        currentStreak: 2,
        bestStreak: 2,
      },
    });

    const result = await service.markPresence(USER_ID);

    expect(result.weekStudy[4]).toBe(true);
    expect(result.currentStreak).toBe(3);
    expect(result.bestStreak).toBe(3);
  });

  it('resets the streak to 1 after a skipped day', async () => {
    const { service } = makeService({
      existingStreak: {
        userId: USER_ID,
        weekStartDate: new Date(Date.UTC(2026, 6, 27)),
        // Wednesday: two days before Friday, so Thursday was missed.
        weekStudy: [false, false, true, false, false, false, false],
        studyTime: 30,
        currentStreak: 5,
        bestStreak: 5,
      },
    });

    const result = await service.markPresence(USER_ID);

    expect(result.weekStudy[4]).toBe(true);
    expect(result.currentStreak).toBe(1);
    // A reset must not shrink the personal best.
    expect(result.bestStreak).toBe(5);
  });

  it('is idempotent: a second call the same day writes nothing', async () => {
    const { service, userStreakRepository } = makeService({
      existingStreak: {
        userId: USER_ID,
        weekStartDate: new Date(Date.UTC(2026, 6, 27)),
        weekStudy: [false, false, false, true, true, false, false],
        studyTime: 30,
        currentStreak: 2,
        bestStreak: 2,
      },
    });

    const result = await service.markPresence(USER_ID);

    expect(result.currentStreak).toBe(2);
    expect(userStreakRepository.updateOne).not.toHaveBeenCalled();
  });

  it('ticks the Vietnam day for a small-hours check-in, not the UTC one', async () => {
    // 00:30 Friday in Vietnam.
    jest.setSystemTime(new Date('2026-07-30T17:30:00.000Z'));
    const { service } = makeService();

    const result = await service.markPresence(USER_ID);

    expect(result.weekStudy[4]).toBe(true); // Friday
    expect(result.weekStudy[3]).toBe(false); // NOT Thursday
  });

  it('ticks the UTC day when the client sends no offset', async () => {
    jest.setSystemTime(new Date('2026-07-30T17:30:00.000Z'));
    const { service } = makeService({ timezoneOffsetHeader: '' });

    const result = await service.markPresence(USER_ID);

    expect(result.weekStudy[3]).toBe(true); // Thursday, per UTC
  });
});

describe('UserStreakService.updateUserStudyTime', () => {
  beforeEach(() => {
    jest.useFakeTimers().setSystemTime(new Date('2026-07-31T01:00:00.000Z'));
  });

  afterEach(() => {
    jest.useRealTimers();
  });

  it('adds study time without ticking the day', async () => {
    const { service, userStreakRepository } = makeService({
      keypointMinutes: 7,
    });

    await service.updateUserStudyTime({
      grade: GradeResultType.KEYPOINT,
      lessonType: LessonType.LESSON,
      dto: { userId: USER_ID, keypoints: [{ keypointId: 'kp-1' }] },
    });

    expect(userStreakRepository.updateOne).toHaveBeenCalledTimes(1);
    const payload = userStreakRepository.updateOne.mock.calls[0][1];
    expect(payload.studyTime).toBe(7);
    // Finishing a keypoint no longer counts the day — presence does.
    expect(payload.weekStudy).toEqual([
      false,
      false,
      false,
      false,
      false,
      false,
      false,
    ]);
    expect(payload.currentStreak).toBe(0);
  });

  it('writes nothing when the activity carries no study time', async () => {
    const { service, userStreakRepository } = makeService({
      keypointMinutes: 0,
    });

    await service.updateUserStudyTime({
      grade: GradeResultType.KEYPOINT,
      lessonType: LessonType.LESSON,
      dto: { userId: USER_ID, keypoints: [{ keypointId: 'kp-1' }] },
    });

    expect(userStreakRepository.updateOne).not.toHaveBeenCalled();
  });
});
