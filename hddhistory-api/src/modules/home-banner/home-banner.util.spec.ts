import { campaignKeyFor } from '@utils/promo-campaign.util';
import { resolveViewerMarkets } from '@utils/viewer-market.util';

import {
  resolveConfiguredSlides,
  visibleSlidesFor,
} from './home-banner.util';

describe('resolveConfiguredSlides', () => {
  /**
   * The property that lets the carousel ship without a migration: a document
   * written before slides existed carries one `imageUrl`, and that banner must
   * keep showing as slide 1 rather than vanishing.
   */
  it('reads a pre-carousel config as a single slide', () => {
    expect(
      resolveConfiguredSlides({
        imageUrl: 'https://cdn.test/old.png',
        linkUrl: 'https://meup.training/r/old',
        countries: ['VN'],
      }),
    ).toEqual([
      {
        imageUrl: 'https://cdn.test/old.png',
        linkUrl: 'https://meup.training/r/old',
        countries: ['VN'],
        enabled: true,
      },
    ]);
  });

  it('prefers slides once they exist, ignoring the legacy fields', () => {
    const slides = [{ imageUrl: 'https://cdn.test/a.png', linkUrl: '' }];

    expect(
      resolveConfiguredSlides({ slides, imageUrl: 'https://cdn.test/old.png' }),
    ).toBe(slides);
  });

  it('is empty when nothing is configured at all', () => {
    expect(resolveConfiguredSlides({})).toEqual([]);
    expect(resolveConfiguredSlides({ imageUrl: '   ' })).toEqual([]);
    expect(resolveConfiguredSlides({ slides: [] , imageUrl: '' })).toEqual([]);
  });
});

describe('visibleSlidesFor', () => {
  const slide = (
    imageUrl: string,
    countries?: string[],
    enabled?: boolean,
  ) => ({ imageUrl, linkUrl: `${imageUrl}/link`, countries, enabled });

  it('keeps order and drops the slides this viewer must not see', () => {
    const slides = [
      slide('vn', ['VN']),
      slide('jp', ['JP']),
      slide('all'),
    ];

    expect(visibleSlidesFor(slides, ['VN']).map(s => s.imageUrl)).toEqual([
      'vn',
      'all',
    ]);
    expect(visibleSlidesFor(slides, ['JP']).map(s => s.imageUrl)).toEqual([
      'jp',
      'all',
    ]);
  });

  /**
   * What the per-slide markets buy: ONE config serves both markets, and the dots
   * the app draws count only the slides that viewer was given.
   */
  it('gives a Vietnamese abroad both their market slides', () => {
    const markets = resolveViewerMarkets({
      cfCountry: 'JP',
      appLanguage: 'vi',
    });

    expect(
      visibleSlidesFor([slide('vn', ['VN']), slide('jp', ['JP'])], markets).map(
        s => s.imageUrl,
      ),
    ).toEqual(['vn', 'jp']);
  });

  it('drops a slide whose switch is off', () => {
    expect(visibleSlidesFor([slide('a', [], false)], ['VN'])).toEqual([]);
    expect(visibleSlidesFor([slide('a', [], true)], ['VN'])).toHaveLength(1);
    // Absent means visible: a slide nobody touched the switch on is one they
    // added to show.
    expect(visibleSlidesFor([slide('a')], ['VN'])).toHaveLength(1);
  });

  /**
   * The admin adds a row and uploads into it afterwards. A saved half-filled row
   * must not become a blank slide with a dot of its own.
   */
  it('drops a slide with no image', () => {
    expect(visibleSlidesFor([slide(''), slide('  ')], ['VN'])).toEqual([]);
  });

  it('trims what it hands the app, and stamps the campaign key', () => {
    expect(
      visibleSlidesFor([{ imageUrl: ' a.png ', linkUrl: ' b ' }], ['VN']),
    ).toEqual([
      // campaignKeyFor trims too, so the key follows the CREATIVE, not the
      // admin's stray spaces.
      { campaignKey: campaignKeyFor('a.png', 'b'), imageUrl: 'a.png', linkUrl: 'b' },
    ]);
  });

  it('hides a targeted slide from a viewer it can place nowhere', () => {
    expect(visibleSlidesFor([slide('vn', ['VN'])], [])).toEqual([]);
    expect(visibleSlidesFor([slide('all')], [])).toHaveLength(1);
  });

  it('filters by the viewer language when a slide targets locales', () => {
    const slides = [
      { ...slide('vi'), locales: ['vi'] },
      { ...slide('en'), locales: ['en'] },
      slide('all'),
    ];

    expect(visibleSlidesFor(slides, ['VN'], 'vi').map(s => s.imageUrl)).toEqual(
      ['vi', 'all'],
    );
    // An unreadable language hides TARGETED slides only — same contract as the
    // market rule.
    expect(visibleSlidesFor(slides, ['VN'], '').map(s => s.imageUrl)).toEqual([
      'all',
    ]);
  });

  it('respects the campaign window, with null bounds open', () => {
    const now = new Date('2027-02-10T00:00:00Z');
    const staged = { ...slide('later'), startAt: new Date('2027-03-01T00:00:00Z') };
    const expired = { ...slide('done'), endAt: new Date('2027-01-01T00:00:00Z') };
    const live = {
      ...slide('live'),
      startAt: new Date('2027-02-01T00:00:00Z'),
      endAt: new Date('2027-02-20T00:00:00Z'),
    };

    expect(
      visibleSlidesFor([staged, expired, live, slide('all')], ['VN'], '', now).map(
        s => s.imageUrl,
      ),
    ).toEqual(['live', 'all']);
  });

  it('shows higher priority first, ties keeping the array order', () => {
    const slides = [
      { ...slide('second'), priority: 1 },
      { ...slide('third') },
      { ...slide('first'), priority: 5 },
      { ...slide('fourth'), priority: 0 },
    ];

    expect(visibleSlidesFor(slides, ['VN']).map(s => s.imageUrl)).toEqual([
      'first',
      'second',
      'third',
      'fourth',
    ]);
  });
});
