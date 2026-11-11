import {
  isVisibleInMarkets,
  resolveViewerMarkets,
} from '@utils/viewer-market.util';

import {
  marketVisibilityFilter,
  viewerMarketsFromHeaders,
  withMarketVisibility,
} from './market-query.util';

/**
 * The clause is only correct insofar as it agrees with the in-memory rule the
 * Home banner already ships. These tests assert the two answer the same, since
 * a drift between them would show up as "the banner reached them but the
 * course didn't" — a report nobody can act on.
 */
describe('marketVisibilityFilter', () => {
  const matches = (countries: string[] | undefined, viewerMarkets: string[]) => {
    const { $or } = marketVisibilityFilter(viewerMarkets) as any;
    const [emptyClause, missingClause, inClause] = $or;

    if (countries === undefined) return Boolean(missingClause);

    return (
      (countries.length === 0 && emptyClause.countries.$size === 0) ||
      countries.some(c => inClause.countries.$in.includes(c))
    );
  };

  it.each([
    ['untargeted, viewer in Vietnam', [], ['VN']],
    ['untargeted, viewer nowhere', [], []],
    ['targeted at VN, viewer in Vietnam', ['VN'], ['VN']],
    ['targeted at VN, diaspora reader (JP address, vi app)', ['VN'], ['JP', 'VN']],
  ])('shows a course: %s', (_label, countries, viewerMarkets) => {
    expect(matches(countries as string[], viewerMarkets as string[])).toBe(true);
    expect(isVisibleInMarkets(countries as string[], viewerMarkets as string[])).toBe(true);
  });

  it.each([
    ['targeted at VN, viewer in Japan', ['VN'], ['JP']],
    ['targeted at VN, viewer we could not place', ['VN'], []],
  ])('hides a course: %s', (_label, countries, viewerMarkets) => {
    expect(matches(countries as string[], viewerMarkets as string[])).toBe(false);
    expect(isVisibleInMarkets(countries as string[], viewerMarkets as string[])).toBe(false);
  });

  it('treats a missing countries field as untargeted', () => {
    expect(matches(undefined, ['JP'])).toBe(true);
  });
});

describe('withMarketVisibility', () => {
  /**
   * The regression this helper exists for: `findOption` builds the search as
   * `$or`, and merging a second `$or` by spread would drop the search with no
   * error to show for it.
   */
  it('keeps an existing $or instead of overwriting it', () => {
    const search = { $or: [{ 'title.vi': /toán/ }] };

    const merged = withMarketVisibility(search, ['VN']) as any;

    expect(merged.$and).toHaveLength(2);
    expect(merged.$and[0]).toBe(search);
    expect(merged.$and[1].$or).toHaveLength(3);
    expect(merged.$or).toBeUndefined();
  });

  it('leaves the filter untouched for a caller that must not be filtered', () => {
    const where = { status: 'published' };

    // null/undefined = admin or scheduler: no viewer, so no targeting.
    expect(withMarketVisibility(where, null)).toBe(where);
    expect(withMarketVisibility(where, undefined)).toBe(where);
  });

  it('still filters for a viewer placed in no market at all', () => {
    // `[]` is a real viewer we could not place — NOT the same as null. They
    // see untargeted courses only.
    const merged = withMarketVisibility({}, []) as any;

    expect(merged.$and).toBeDefined();
    expect(merged.$and[1].$or[2].countries.$in).toEqual([]);
  });
});

describe('viewerMarketsFromHeaders', () => {
  it('reads the same three signals resolveViewerMarkets does', () => {
    const headers = {
      'cf-ipcountry': 'JP',
      'x-device-country': 'vn',
      lang: 'vi',
    };

    expect(viewerMarketsFromHeaders(headers).sort()).toEqual(
      resolveViewerMarkets({
        cfCountry: 'JP',
        deviceCountry: 'vn',
        appLanguage: 'vi',
      }).sort(),
    );
  });

  it('is empty rather than throwing when there are no headers', () => {
    expect(viewerMarketsFromHeaders(undefined)).toEqual([]);
  });
});
