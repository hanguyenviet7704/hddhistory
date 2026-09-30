import { shouldAskRating, RatingAskConfig, RatingAskState } from './rating-ask-gate';

const CONFIG: RatingAskConfig = {
  ratingAskEnabled: true,
  ratingAskMinDays: 0,
  ratingAskSnoozeDays: 0,
  ratingAskEveryNthExit: 1,
  ratingAskProbability: 100,
  ratingAskMaxPerUser: 0,
};

const STATE: RatingAskState = {
  ratingAskedAt: null,
  ratingSnoozedAt: null,
  ratingAskCount: 0,
  exitCount: 0,
};

const NOW = new Date('2026-09-14T00:00:00.000Z');
const daysAgo = (n: number) => new Date(NOW.getTime() - n * 24 * 60 * 60 * 1000);

/** Every gate neutral — the ask goes through. */
const ask = (
  config: Partial<RatingAskConfig> = {},
  state: Partial<RatingAskState> = {},
  roll = 0,
) =>
  shouldAskRating({
    config: { ...CONFIG, ...config },
    state: { ...STATE, ...state },
    now: NOW,
    roll: () => roll,
  });

describe('shouldAskRating', () => {
  it('asks when every gate is neutral', () => {
    expect(ask()).toBe(true);
  });

  it('the master switch closes it', () => {
    expect(ask({ ratingAskEnabled: false })).toBe(false);
  });

  describe('giãn cách sau khi đã gửi', () => {
    it('holds somebody who answered inside the window', () => {
      expect(ask({ ratingAskMinDays: 7 }, { ratingAskedAt: daysAgo(3) })).toBe(false);
    });

    it('asks again once the window has passed', () => {
      expect(ask({ ratingAskMinDays: 7 }, { ratingAskedAt: daysAgo(8) })).toBe(true);
    });

    it('0 days means the window is off', () => {
      expect(ask({ ratingAskMinDays: 0 }, { ratingAskedAt: daysAgo(0) })).toBe(true);
    });
  });

  describe('giãn cách sau khi "Để sau"', () => {
    it('holds somebody who just deferred', () => {
      expect(ask({ ratingAskSnoozeDays: 3 }, { ratingSnoozedAt: daysAgo(1) })).toBe(false);
    });

    it('asks again after the snooze', () => {
      expect(ask({ ratingAskSnoozeDays: 3 }, { ratingSnoozedAt: daysAgo(4) })).toBe(true);
    });
  });

  describe('mỗi N lần thoát', () => {
    it('counts the exit about to happen, not the one already counted', () => {
      // 2 exits so far; this one is the 3rd, so N=3 lets it through.
      expect(ask({ ratingAskEveryNthExit: 3 }, { exitCount: 2 })).toBe(true);
    });

    it('stays quiet on the exits in between', () => {
      expect(ask({ ratingAskEveryNthExit: 3 }, { exitCount: 0 })).toBe(false);
      expect(ask({ ratingAskEveryNthExit: 3 }, { exitCount: 1 })).toBe(false);
    });

    it('1 means every exit', () => {
      expect(ask({ ratingAskEveryNthExit: 1 }, { exitCount: 41 })).toBe(true);
    });
  });

  describe('xác suất', () => {
    it('a roll under the percentage passes', () => {
      expect(ask({ ratingAskProbability: 30 }, {}, 0.29)).toBe(true);
    });

    it('a roll on or over it does not', () => {
      expect(ask({ ratingAskProbability: 30 }, {}, 0.3)).toBe(false);
    });

    it('100 never rolls anybody out', () => {
      expect(ask({ ratingAskProbability: 100 }, {}, 0.999)).toBe(true);
    });

    it('0 closes the gate entirely', () => {
      expect(ask({ ratingAskProbability: 0 }, {}, 0)).toBe(false);
    });
  });

  describe('trần mỗi người', () => {
    it('stops for good at the ceiling', () => {
      expect(ask({ ratingAskMaxPerUser: 2 }, { ratingAskCount: 2 })).toBe(false);
    });

    it('lets the last one through', () => {
      expect(ask({ ratingAskMaxPerUser: 2 }, { ratingAskCount: 1 })).toBe(true);
    });

    it('0 means no ceiling', () => {
      expect(ask({ ratingAskMaxPerUser: 0 }, { ratingAskCount: 99 })).toBe(true);
    });
  });

  it('every gate must pass, not just one', () => {
    expect(
      ask(
        { ratingAskMinDays: 7, ratingAskEveryNthExit: 3 },
        { ratingAskedAt: daysAgo(8), exitCount: 1 },
      ),
    ).toBe(false);
  });
});
