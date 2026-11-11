import {
  isVisibleInMarkets,
  normalizeCountryCodes,
  resolveViewerMarkets,
} from './viewer-market.util';

describe('resolveViewerMarkets', () => {
  /**
   * The case this whole union exists for: a Vietnamese living in Japan. The IP
   * and the device region both say JP; only the app language says who the
   * campaign is for. Under the old single-country rule they were invisible to
   * every Vietnam campaign.
   */
  it('places a Vietnamese abroad in both markets', () => {
    expect(
      resolveViewerMarkets({
        cfCountry: 'JP',
        deviceCountry: 'JP',
        appLanguage: 'vi',
      }),
    ).toEqual(['JP', 'VN']);
  });

  it('keeps both country signals when they disagree', () => {
    expect(
      resolveViewerMarkets({ cfCountry: 'JP', deviceCountry: 'VN' }),
    ).toEqual(['JP', 'VN']);
  });

  it('de-duplicates signals that agree', () => {
    expect(
      resolveViewerMarkets({
        cfCountry: 'vn',
        deviceCountry: 'VN',
        appLanguage: 'vi',
      }),
    ).toEqual(['VN']);
  });

  /**
   * `en` is the app's fallback locale for the whole world, so it stands in for
   * no market — otherwise every English reader anywhere would match a US or GB
   * campaign.
   */
  it('reads English as no market at all', () => {
    expect(resolveViewerMarkets({ appLanguage: 'en' })).toEqual([]);
    expect(resolveViewerMarkets({ cfCountry: 'JP', appLanguage: 'en' })).toEqual(
      ['JP'],
    );
  });

  it('maps the other shipped languages', () => {
    expect(resolveViewerMarkets({ appLanguage: 'ja' })).toEqual(['JP']);
    expect(resolveViewerMarkets({ appLanguage: 'ko' })).toEqual(['KR']);
    expect(resolveViewerMarkets({ appLanguage: 'zh' })).toEqual([
      'CN',
      'TW',
      'HK',
    ]);
  });

  it('tolerates a full locale and odd casing in lang', () => {
    expect(resolveViewerMarkets({ appLanguage: 'VI-VN' })).toEqual(['VN']);
    expect(resolveViewerMarkets({ appLanguage: 'vi_VN' })).toEqual(['VN']);
  });

  it('ignores unusable country values', () => {
    expect(
      resolveViewerMarkets({ cfCountry: 'XX', deviceCountry: 'T1' }),
    ).toEqual([]);
    expect(resolveViewerMarkets({ cfCountry: 'VNM' })).toEqual([]);
    expect(resolveViewerMarkets({})).toEqual([]);
  });
});

describe('isVisibleInMarkets', () => {
  /**
   * The property that makes this deployable without a migration: existing
   * config documents have no `countries`, read back as [], and must keep
   * showing to everyone exactly as they did before.
   */
  it('shows to everyone when no countries are set', () => {
    expect(isVisibleInMarkets([], ['VN'])).toBe(true);
    expect(isVisibleInMarkets([], [])).toBe(true);
    expect(isVisibleInMarkets(undefined, [])).toBe(true);
  });

  it('shows on ANY overlap and hides with none', () => {
    expect(isVisibleInMarkets(['VN'], ['VN'])).toBe(true);
    expect(isVisibleInMarkets(['VN', 'JP'], ['JP'])).toBe(true);
    expect(isVisibleInMarkets(['VN'], ['JP'])).toBe(false);
  });

  /**
   * What the union buys, stated as a test: the same viewer sees a Japan campaign
   * (they are there) and a Vietnam campaign (they read Vietnamese).
   */
  it('shows both campaigns to a Vietnamese abroad', () => {
    const markets = resolveViewerMarkets({
      cfCountry: 'JP',
      appLanguage: 'vi',
    });

    expect(isVisibleInMarkets(['JP'], markets)).toBe(true);
    expect(isVisibleInMarkets(['VN'], markets)).toBe(true);
    expect(isVisibleInMarkets(['KR'], markets)).toBe(false);
  });

  /**
   * The decision most likely to surprise someone operating this: a targeted
   * banner is HIDDEN from a viewer we could place nowhere. The admin said "only
   * these countries", and showing it to an unknown viewer does the opposite.
   */
  it('hides a targeted banner from an unplaceable viewer', () => {
    expect(isVisibleInMarkets(['VN'], [])).toBe(false);
  });
});

describe('normalizeCountryCodes', () => {
  it('upper-cases, trims and de-duplicates', () => {
    expect(normalizeCountryCodes([' vn ', 'VN', 'jp'])).toEqual(['VN', 'JP']);
  });

  it('drops anything that is not two letters', () => {
    expect(normalizeCountryCodes(['VN', 'VNM', '', '1', 'J P'])).toEqual(['VN']);
  });

  it('handles missing input', () => {
    expect(normalizeCountryCodes(undefined)).toEqual([]);
    expect(normalizeCountryCodes([])).toEqual([]);
  });

  /**
   * Normalising on write is what lets the matcher be a plain `includes`. If
   * 'vn' could reach Mongo, every read path would have to remember to
   * upper-case, and the one that forgot would silently match nothing.
   */
  it('produces values the matcher accepts', () => {
    const stored = normalizeCountryCodes(['vn']);

    expect(
      isVisibleInMarkets(
        stored,
        resolveViewerMarkets({ cfCountry: 'vn' }),
      ),
    ).toBe(true);
  });
});
