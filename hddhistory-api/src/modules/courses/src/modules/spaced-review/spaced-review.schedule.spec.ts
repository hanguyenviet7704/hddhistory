import {
  firstReviewAt,
  nextReview,
  REVIEW_INTERVAL_DAYS,
} from './spaced-review.schedule';

const DAY_MS = 24 * 60 * 60 * 1000;
const now = new Date('2026-10-28T08:00:00.000Z');
const daysFromNow = (date: Date) => (date.getTime() - now.getTime()) / DAY_MS;

describe('spaced-review schedule', () => {
  it('đưa keypoint vừa học vào ôn sau 1 ngày', () => {
    expect(daysFromNow(firstReviewAt(now))).toBe(1);
  });

  it('ôn đúng thì leo lần lượt 3 → 7 → 14 → 30 ngày', () => {
    let step = 0;
    const gaps: number[] = [];
    for (let i = 0; i < 4; i += 1) {
      const next = nextReview(step, true, now);
      gaps.push(daysFromNow(next.dueAt));
      step = next.step;
    }
    expect(gaps).toEqual([3, 7, 14, 30]);
  });

  it('kịch trần ở bậc cuối', () => {
    const last = REVIEW_INTERVAL_DAYS.length - 1;
    const next = nextReview(last, true, now);
    expect(next.step).toBe(last);
    expect(daysFromNow(next.dueAt)).toBe(30);
  });

  it('ôn sai thì về bậc 0, mai ôn lại', () => {
    const next = nextReview(3, false, now);
    expect(next.step).toBe(0);
    expect(daysFromNow(next.dueAt)).toBe(1);
  });

  it('bậc rác (âm, thiếu) được coi như bậc 0', () => {
    expect(nextReview(-2, true, now).step).toBe(1);
    expect(nextReview(undefined as unknown as number, true, now).step).toBe(1);
  });
});
