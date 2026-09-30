import {
  dayKeyFor,
  isUserLessonKeypointId,
  resolveTimezoneOffsetMinutes,
} from './keypoint-access.util';
import { claimedKeypointIds } from './repository/keypoint-daily-claim.repository';

/**
 * "Which day is it for this reader" is the whole quota rule, so these are the cases
 * that decide when someone's free keypoint arrives.
 * See `hddhistory-api/plans/260812-daily-keypoint-quota/README.md`.
 */
describe('dayKeyFor', () => {
  const VN = 420; // UTC+7

  it('uses the reader clock, not the server one', () => {
    // 23:30 UTC on the 11th is already 06:30 on the 12th in Vietnam.
    const at = new Date('2026-08-11T23:30:00Z');

    expect(dayKeyFor(at, 0)).toBe('2026-08-11');
    expect(dayKeyFor(at, VN)).toBe('2026-08-12');
  });

  /**
   * The case that made this a header-driven decision rather than server time: a
   * Vietnamese reader studying after midnight would otherwise have their session
   * filed under yesterday, and find their free keypoint already spent.
   */
  it('gives a Vietnamese reader at 00:30 the new day', () => {
    // 00:30 on the 12th in Vietnam is 17:30 on the 11th UTC.
    expect(dayKeyFor(new Date('2026-08-11T17:30:00Z'), VN)).toBe('2026-08-12');
  });

  it('handles negative offsets', () => {
    // 01:00 UTC on the 12th is still the 11th in New York (UTC-5).
    expect(dayKeyFor(new Date('2026-08-12T01:00:00Z'), -300)).toBe('2026-08-11');
  });

  it('pads month and day so keys sort and compare as strings', () => {
    expect(dayKeyFor(new Date('2026-01-05T12:00:00Z'), 0)).toBe('2026-01-05');
  });

  it('is stable across the same reader day', () => {
    const morning = dayKeyFor(new Date('2026-08-12T01:00:00Z'), VN);
    const evening = dayKeyFor(new Date('2026-08-12T15:00:00Z'), VN);

    expect(morning).toBe(evening);
  });
});

describe('resolveTimezoneOffsetMinutes', () => {
  it('reads the header the app already sends', () => {
    expect(resolveTimezoneOffsetMinutes('420')).toBe(420);
    expect(resolveTimezoneOffsetMinutes(' -300 ')).toBe(-300);
  });

  it('falls back to UTC when the header is missing or junk', () => {
    expect(resolveTimezoneOffsetMinutes()).toBe(0);
    expect(resolveTimezoneOffsetMinutes('')).toBe(0);
    expect(resolveTimezoneOffsetMinutes('abc')).toBe(0);
  });

  /**
   * The offset decides which day a claim lands in, so an absurd value would hand out
   * an extra free keypoint every time it changed. Real offsets span UTC-12 to UTC+14.
   */
  it('clamps values outside any real timezone', () => {
    expect(resolveTimezoneOffsetMinutes('99999')).toBe(14 * 60);
    expect(resolveTimezoneOffsetMinutes('-99999')).toBe(-12 * 60);
  });
});

describe('isUserLessonKeypointId', () => {
  /**
   * The guard that keeps a reader from being charged for material they uploaded
   * themselves. Lives on the server as well as in the app because this is a
   * content gate — a client that forgets it must not be able to meter their own
   * lesson (caught on device 2026-08-12, the quota capped a generated lesson at
   * card 3).
   */
  it('recognises a synthesised generated-lesson id', () => {
    expect(isUserLessonKeypointId('abc::user-lesson::kp-0')).toBe(true);
  });

  it('leaves catalogue ids alone', () => {
    expect(isUserLessonKeypointId('6a4f07e284c121d60e272c00')).toBe(false);
    expect(isUserLessonKeypointId('')).toBe(false);
    expect(isUserLessonKeypointId()).toBe(false);
  });
});

/**
 * Back-compat that decides whether a reader gets a SECOND free ticket for a keypoint
 * they already spent one on. Rows written before the quota could exceed one per day
 * carry `keypointId` and no array (see the day-row shape in the schema).
 */
describe('claimedKeypointIds', () => {
  it('reads the array when the row has one', () => {
    expect(claimedKeypointIds({ keypointId: 'a', keypointIds: ['a', 'b'] })).toEqual(['a', 'b']);
  });

  it('falls back to the single legacy field', () => {
    expect(claimedKeypointIds({ keypointId: 'a', keypointIds: [] })).toEqual(['a']);
    expect(claimedKeypointIds({ keypointId: 'a', keypointIds: undefined })).toEqual(['a']);
  });

  it('is empty for no row and for a row holding nothing', () => {
    expect(claimedKeypointIds(null)).toEqual([]);
    expect(claimedKeypointIds({ keypointId: undefined, keypointIds: [] })).toEqual([]);
  });
});
