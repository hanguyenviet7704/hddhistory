import { shuffle, startOfCurrentWeek } from './explore.helper';

// Vietnam is UTC+7 year round, so a local Monday 00:00 is the Sunday before at
// 17:00 UTC.
const VN = 'Asia/Ho_Chi_Minh';

describe('startOfCurrentWeek', () => {
  it('returns the Monday just gone, at local midnight', () => {
    // Wed 16 Sep 2026, 11:00 Hanoi (04:00 UTC).
    const now = new Date('2026-09-16T04:00:00.000Z');
    expect(startOfCurrentWeek(now, VN)).toEqual(
      new Date('2026-09-13T17:00:00.000Z'), // Mon 14 Sep 00:00 +07
    );
  });

  it("counts the reader's Monday, not the server's UTC day", () => {
    // 00:30 Monday in Hanoi is still Sunday in UTC. Reading the UTC date here
    // would hand back the PREVIOUS Monday and the strip would report a
    // fortnight instead of a week.
    const now = new Date('2026-09-13T17:30:00.000Z'); // Mon 14 Sep 00:30 +07
    expect(startOfCurrentWeek(now, VN)).toEqual(
      new Date('2026-09-13T17:00:00.000Z'),
    );
  });

  it('keeps Sunday inside the week that began six days earlier', () => {
    // Sun 20 Sep 2026, 22:00 Hanoi. A Monday-to-Saturday window would drop
    // this reader out of every week.
    const now = new Date('2026-09-20T15:00:00.000Z');
    expect(startOfCurrentWeek(now, VN)).toEqual(
      new Date('2026-09-13T17:00:00.000Z'),
    );
  });

  it('rolls over at the Monday boundary', () => {
    const justBefore = new Date('2026-09-20T16:59:00.000Z'); // Sun 23:59 +07
    const justAfter = new Date('2026-09-20T17:01:00.000Z'); // Mon 00:01 +07
    expect(startOfCurrentWeek(justBefore, VN)).toEqual(
      new Date('2026-09-13T17:00:00.000Z'),
    );
    expect(startOfCurrentWeek(justAfter, VN)).toEqual(
      new Date('2026-09-20T17:00:00.000Z'),
    );
  });
});

describe('shuffle', () => {
  const items = ['a', 'b', 'c', 'd', 'e', 'f', 'g', 'h'];

  it('keeps every item exactly once', () => {
    expect([...shuffle(items)].sort()).toEqual([...items].sort());
  });

  it('does not mutate the input', () => {
    const input = [...items];
    shuffle(input);
    expect(input).toEqual(items);
  });

  it('does actually reorder', () => {
    // One run can legitimately come back in order; twenty all coming back in
    // order means the shuffle is a no-op.
    const runs = Array.from({ length: 20 }, () => shuffle(items));
    expect(runs.some(run => run.join() !== items.join())).toBe(true);
  });
});
