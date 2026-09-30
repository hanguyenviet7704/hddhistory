import { pickPooledScene } from './coach-situation-pool.helper';

const scene = (id: string, level: number | null, slot = 0) => ({
  id,
  level,
  slot,
});

describe('pickPooledScene', () => {
  it('prefers a scene at exactly the level that was asked for', () => {
    expect(
      pickPooledScene({
        pool: [scene('a', 2), scene('b', 4), scene('c', 3)],
        wantedLevel: 4,
        avoidIds: [],
      })?.id,
    ).toBe('b');
  });

  it('never returns a scene this reader has already been shown', () => {
    // The whole point of a fallback is to be better than nothing. Handing back
    // the scene they just practised is worse than nothing.
    expect(
      pickPooledScene({
        pool: [scene('seen', 4), scene('fresh', 2)],
        wantedLevel: 4,
        avoidIds: ['seen'],
      })?.id,
    ).toBe('fresh');
  });

  it('falls to the nearest level when the exact rung is missing', () => {
    expect(
      pickPooledScene({
        pool: [scene('far', 1), scene('near', 3)],
        wantedLevel: 4,
        avoidIds: [],
      })?.id,
    ).toBe('near');
  });

  it('breaks a tie upward, because the only asked-for level means "harder"', () => {
    // `wantedLevel` is set by "Luyện cảnh khó hơn" and nothing else. Answering
    // a request to go up with the rung BELOW is the one direction that reads as
    // the button having failed.
    expect(
      pickPooledScene({
        pool: [scene('down', 2), scene('up', 4)],
        wantedLevel: 3,
        avoidIds: [],
      })?.id,
    ).toBe('up');
  });

  it('reads a legacy row with no level as the easiest rung', () => {
    expect(
      pickPooledScene({
        pool: [scene('legacy', null)],
        wantedLevel: 1,
        avoidIds: [],
      })?.id,
    ).toBe('legacy');
  });

  it('takes the lowest slot when level cannot separate two scenes', () => {
    // Stable on purpose: two calls a second apart must not hand two different
    // scenes to the same reader.
    expect(
      pickPooledScene({
        pool: [scene('later', 3, 9), scene('earlier', 3, 2)],
        wantedLevel: 3,
        avoidIds: [],
      })?.id,
    ).toBe('earlier');
  });

  it('is null when every scene is one they have seen', () => {
    expect(
      pickPooledScene({
        pool: [scene('a', 1), scene('b', 2)],
        wantedLevel: 1,
        avoidIds: ['a', 'b'],
      }),
    ).toBeNull();
  });

  it('is null on an empty pool rather than inventing something', () => {
    expect(
      pickPooledScene({ pool: [], wantedLevel: 3, avoidIds: [] }),
    ).toBeNull();
  });
});
