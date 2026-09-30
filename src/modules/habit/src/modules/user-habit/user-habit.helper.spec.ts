import {
  computeStreakFromDoneDates,
  localDateOnly,
  localDateOnlyFromOffsetMinutes,
  normalizeDateOnly,
} from './user-habit.helper';

const utcMidnight = (iso: string) => new Date(`${iso}T00:00:00.000Z`);

describe('localDateOnly', () => {
  it('uses the READER\'s calendar day, not the server\'s UTC date', () => {
    // The bug this exists for: 01:30 on 1 Aug in Vietnam is still 31 Jul in UTC,
    // so a habit ticked then was filed under the previous day — and the 21:00
    // reminder kept insisting it was unchecked.
    expect(
      localDateOnly('Asia/Ho_Chi_Minh', new Date('2026-07-31T18:30:00.000Z')),
    ).toEqual(utcMidnight('2026-08-01'));
  });

  it('agrees with the UTC date when the two days line up', () => {
    expect(
      localDateOnly('Asia/Ho_Chi_Minh', new Date('2026-07-31T02:00:00.000Z')),
    ).toEqual(utcMidnight('2026-07-31'));
  });

  it('handles a zone behind UTC too', () => {
    // 20:00 on 31 Jul in Los Angeles is already 1 Aug in UTC.
    expect(
      localDateOnly('America/Los_Angeles', new Date('2026-08-01T03:00:00.000Z')),
    ).toEqual(utcMidnight('2026-07-31'));
  });

  it('falls back to the server UTC date without a zone', () => {
    const now = new Date('2026-07-31T18:30:00.000Z');
    expect(localDateOnly(undefined, now)).toEqual(normalizeDateOnly(now));
    expect(localDateOnly('', now)).toEqual(normalizeDateOnly(now));
  });

  it('falls back rather than throwing on a zone ICU does not know', () => {
    const now = new Date('2026-07-31T18:30:00.000Z');
    expect(localDateOnly('Mars/Olympus_Mons', now)).toEqual(
      normalizeDateOnly(now),
    );
  });

  it('returns a date-only value (midnight UTC)', () => {
    const value = localDateOnly(
      'Asia/Ho_Chi_Minh',
      new Date('2026-07-31T18:30:00.000Z'),
    );
    expect(value.getUTCHours()).toBe(0);
    expect(value.getUTCMinutes()).toBe(0);
    expect(value.getUTCSeconds()).toBe(0);
    expect(value.getUTCMilliseconds()).toBe(0);
  });
});

describe('localDateOnlyFromOffsetMinutes', () => {
  it('agrees with the named zone for the 00:00–07:00 Vietnam window', () => {
    const now = new Date('2026-07-31T18:30:00.000Z'); // 01:30 on 1 Aug in Hanoi
    expect(localDateOnlyFromOffsetMinutes(420, now)).toEqual(
      localDateOnly('Asia/Ho_Chi_Minh', now),
    );
    expect(localDateOnlyFromOffsetMinutes(420, now)).toEqual(
      utcMidnight('2026-08-01'),
    );
  });

  it('handles a negative offset', () => {
    const now = new Date('2026-08-01T03:00:00.000Z'); // 20:00 on 31 Jul in LA
    expect(localDateOnlyFromOffsetMinutes(-420, now)).toEqual(
      utcMidnight('2026-07-31'),
    );
  });

  it('is the plain UTC date at offset 0 — the no-header fallback', () => {
    const now = new Date('2026-07-31T18:30:00.000Z');
    expect(localDateOnlyFromOffsetMinutes(0, now)).toEqual(
      normalizeDateOnly(now),
    );
  });
});

describe('computeStreakFromDoneDates', () => {
  it('counts a run ending on the passed-in today', () => {
    const result = computeStreakFromDoneDates(
      [utcMidnight('2026-07-30'), utcMidnight('2026-07-31')],
      utcMidnight('2026-07-31'),
    );
    expect(result.currentStreak).toBe(2);
    expect(result.lastCheckInDate).toEqual(utcMidnight('2026-07-31'));
  });

  it('still counts a run that ends yesterday', () => {
    const result = computeStreakFromDoneDates(
      [utcMidnight('2026-07-30'), utcMidnight('2026-07-31')],
      utcMidnight('2026-08-01'),
    );
    expect(result.currentStreak).toBe(2);
  });

  it('breaks the streak once the last done day is 2+ days back', () => {
    const result = computeStreakFromDoneDates(
      [utcMidnight('2026-07-30'), utcMidnight('2026-07-31')],
      utcMidnight('2026-08-02'),
    );
    expect(result.currentStreak).toBe(0);
    expect(result.lastCheckInDate).toEqual(utcMidnight('2026-07-31'));
  });

  it('respects a local today one day ahead of the server UTC date', () => {
    // Same data, two definitions of "today": the reader ticked yesterday and
    // today (local), so the streak must not read as broken just because the
    // server's UTC clock has not rolled over yet.
    const doneDates = [utcMidnight('2026-07-31'), utcMidnight('2026-08-01')];
    expect(
      computeStreakFromDoneDates(doneDates, utcMidnight('2026-08-01'))
        .currentStreak,
    ).toBe(2);
  });

  it('reports nothing for a habit with no done days', () => {
    const result = computeStreakFromDoneDates([], utcMidnight('2026-07-31'));
    expect(result.currentStreak).toBe(0);
    expect(result.lastCheckInDate).toBeNull();
  });
});
