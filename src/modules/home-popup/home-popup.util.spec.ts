import {
  campaignKeyFor,
  candidatePopupsFor,
  isCampaignKey,
  resolveConfiguredPopups,
} from './home-popup.util';

/**
 * The popup's whole lifecycle behaviour comes out of this one function, so the
 * cases below are the product rules, not string-hashing trivia.
 * See `hddhistory-api/plans/260811-home-popup/README.md`.
 */
describe('campaignKeyFor', () => {
  const IMAGE = 'https://cdn.test/tet-2026.png';
  const LINK = 'https://meup.training/r/tet-2026';

  it('is stable for the same creative', () => {
    expect(campaignKeyFor(IMAGE, LINK)).toBe(campaignKeyFor(IMAGE, LINK));
    expect(campaignKeyFor(IMAGE, LINK)).toMatch(/^[0-9a-f]{16}$/);
  });

  /**
   * The reason the popup is reusable at all: publishing a new creative must reach
   * everyone, including the people who tapped the last one.
   */
  it('changes when the image changes', () => {
    expect(campaignKeyFor('https://cdn.test/other.png', LINK)).not.toBe(
      campaignKeyFor(IMAGE, LINK),
    );
  });

  it('changes when the link changes', () => {
    expect(campaignKeyFor(IMAGE, 'https://meup.training/r/other')).not.toBe(
      campaignKeyFor(IMAGE, LINK),
    );
  });

  /**
   * The mirror image, and the reason this is a hash of content rather than a
   * version counter: restoring a previous creative is the SAME offer, so people
   * who already acted on it are not asked twice.
   */
  it('comes back when a previous creative is restored', () => {
    const original = campaignKeyFor(IMAGE, LINK);
    const replaced = campaignKeyFor('https://cdn.test/other.png', LINK);
    const restored = campaignKeyFor(IMAGE, LINK);

    expect(restored).toBe(original);
    expect(restored).not.toBe(replaced);
  });

  it('ignores surrounding whitespace, so a stray space is not a new campaign', () => {
    expect(campaignKeyFor(`  ${IMAGE} `, ` ${LINK} `)).toBe(
      campaignKeyFor(IMAGE, LINK),
    );
  });

  it('treats a missing link as part of the identity, not as an error', () => {
    expect(campaignKeyFor(IMAGE)).toMatch(/^[0-9a-f]{16}$/);
    expect(campaignKeyFor(IMAGE)).not.toBe(campaignKeyFor(IMAGE, LINK));
  });

  /** No image, no campaign — there is nothing to show and nothing to identify. */
  it('is empty without an image', () => {
    expect(campaignKeyFor('', LINK)).toBe('');
    expect(campaignKeyFor('   ', LINK)).toBe('');
    expect(campaignKeyFor(undefined, LINK)).toBe('');
  });
});

describe('isCampaignKey', () => {
  it('accepts what campaignKeyFor emits', () => {
    expect(isCampaignKey(campaignKeyFor('a.png', 'b'))).toBe(true);
  });

  /**
   * The click endpoint stores this straight from the request body, so anything
   * that is not exactly our shape has to be refused.
   */
  it('refuses anything else', () => {
    expect(isCampaignKey('')).toBe(false);
    expect(isCampaignKey(undefined)).toBe(false);
    expect(isCampaignKey('too-short')).toBe(false);
    expect(isCampaignKey('3F2A1C9D8E7B6A54')).toBe(false); // upper case
    expect(isCampaignKey('3f2a1c9d8e7b6a5')).toBe(false); // 15 chars
    expect(isCampaignKey('3f2a1c9d8e7b6a544')).toBe(false); // 17 chars
    expect(isCampaignKey('../../etc/passwd')).toBe(false);
  });

  it('tolerates whitespace around a real key', () => {
    expect(isCampaignKey(` ${campaignKeyFor('a.png', 'b')} `)).toBe(true);
  });
});

describe('resolveConfiguredPopups', () => {
  /**
   * The property that lets the campaign LIST ship without a migration: a config
   * written before it existed carries one flat creative, and that popup must
   * keep showing as campaign 1 rather than vanishing.
   *
   * `alwaysShow: false` is asserted rather than left out: a flag added later
   * must not change what an older config DOES, and the old behaviour is that
   * tapping retires the popup.
   */
  it('reads a pre-list config as a single campaign', () => {
    expect(
      resolveConfiguredPopups({
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
        alwaysShow: false,
      },
    ]);
  });

  it('prefers the list once it exists, ignoring the legacy fields', () => {
    const popups = [{ imageUrl: 'https://cdn.test/a.png', linkUrl: '' }];

    expect(
      resolveConfiguredPopups({ popups, imageUrl: 'https://cdn.test/old.png' }),
    ).toBe(popups);
  });

  it('is empty when nothing is configured at all', () => {
    expect(resolveConfiguredPopups({})).toEqual([]);
    expect(resolveConfiguredPopups({ imageUrl: '   ' })).toEqual([]);
  });
});

describe('candidatePopupsFor', () => {
  const popup = (imageUrl: string, extra: object = {}) => ({
    imageUrl,
    linkUrl: `${imageUrl}/link`,
    ...extra,
  });

  it('filters like the banner and orders best first', () => {
    const now = new Date('2027-02-10T00:00:00Z');
    const popups = [
      popup('off', { enabled: false }),
      popup('jp', { countries: ['JP'] }),
      popup('en-only', { locales: ['en'] }),
      popup('expired', { endAt: new Date('2027-01-01T00:00:00Z') }),
      popup('runner-up', { priority: 1 }),
      popup('winner', { priority: 9 }),
    ];

    expect(
      candidatePopupsFor(popups, ['VN'], 'vi', now).map(p => p.imageUrl),
    ).toEqual(['winner', 'runner-up']);
  });

  /**
   * Why the caller gets a LIST, not one winner: the top campaign may already be
   * retired for this user, and the next one down must then get its turn.
   */
  it('keeps every eligible campaign so a retired winner has an understudy', () => {
    const popups = [popup('a', { priority: 2 }), popup('b', { priority: 1 })];

    expect(candidatePopupsFor(popups, ['VN'], 'vi')).toHaveLength(2);
  });
});
