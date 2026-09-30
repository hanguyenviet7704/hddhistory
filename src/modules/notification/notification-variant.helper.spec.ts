import {
  highestVariantSeq,
  pickVariant,
  shiftLocalDate,
  variantCooldownMap,
  variantsOf,
  VARIANT_COOLDOWN_DAYS,
} from './notification-variant.helper';
import { NotificationLogStatus } from './notification.enum';
import { INotificationVariant } from './schema/notification-template.schema';

const variant = (key: string, title = `title ${key}`): INotificationVariant => ({
  key,
  copies: { vi: { title, body: '' }, en: { title: `${title} en`, body: '' } },
});

describe('variantsOf', () => {
  it('reads a pre-variants document as one variant', () => {
    // The whole reason live templates need no migration: copy saved in the old
    // single-map shape still has to be sendable.
    const variants = variantsOf({
      copies: { vi: { title: 'legacy', body: '' } },
    });
    expect(variants).toEqual([
      { key: 'v1', copies: { vi: { title: 'legacy', body: '' } } },
    ]);
  });

  it('prefers variants once the document has them', () => {
    const variants = variantsOf({
      copies: { vi: { title: 'legacy', body: '' } },
      variants: [variant('v2'), variant('v3')],
    });
    expect(variants.map(item => item.key)).toEqual(['v2', 'v3']);
  });

  it('ignores a variant with no copy at all', () => {
    const variants = variantsOf({
      variants: [{ key: 'v1', copies: {} }, variant('v2')],
    });
    expect(variants.map(item => item.key)).toEqual(['v2']);
  });

  it('returns nothing for an empty template', () => {
    expect(variantsOf({})).toEqual([]);
  });
});

describe('highestVariantSeq', () => {
  it('reads the highest key rather than counting entries', () => {
    // v2 was deleted. Handing 'v2' to a new wording would let the deleted one's
    // cooldown suppress a sentence that has never been sent.
    expect(highestVariantSeq([variant('v1'), variant('v3')])).toBe(3);
  });

  it('is 0 for a list with no v<n> key', () => {
    expect(highestVariantSeq([])).toBe(0);
    expect(highestVariantSeq([{ key: 'legacy', copies: {} }])).toBe(0);
  });
});

describe('pickVariant', () => {
  const variables = { user_name: 'Ha', course_name: 'Giao tiếp' };
  const always = () => 0;

  it('drops a wording whose content placeholder has nothing to fill it', () => {
    const withTopic: INotificationVariant = {
      key: 'v2',
      copies: { vi: { title: 'Hành trình {topic_name}', body: '' } },
    };
    const pick = pickVariant({
      variants: [withTopic, variant('v1')],
      language: 'vi',
      variables,
      random: always,
    });
    expect(pick?.variant.key).toBe('v1');
  });

  it('greets nobody only when no other wording can render', () => {
    const needsName: INotificationVariant = {
      key: 'v1',
      copies: { vi: { title: 'Chào {user_name}', body: '' } },
    };
    const needsCourse: INotificationVariant = {
      key: 'v2',
      copies: { vi: { title: 'Học "{course_name}"', body: '' } },
    };

    const named = pickVariant({
      variants: [needsName, needsCourse],
      language: 'vi',
      variables: { user_name: '', course_name: 'Giao tiếp' },
      random: always,
    });
    expect(named?.variant.key).toBe('v2');

    const nameless = pickVariant({
      variants: [needsName],
      language: 'vi',
      variables: { user_name: '', course_name: '' },
      random: always,
    });
    expect(nameless?.variant.key).toBe('v1');
  });

  it('skips the wordings used within the cooldown window', () => {
    const pick = pickVariant({
      variants: [variant('v1'), variant('v2'), variant('v3')],
      language: 'vi',
      variables,
      daysSinceLastUse: new Map([
        ['v1', 1],
        ['v2', VARIANT_COOLDOWN_DAYS],
      ]),
      random: always,
    });
    expect(pick?.variant.key).toBe('v3');
  });

  it('relaxes to yesterday-only when every wording is inside the window', () => {
    // Three variants and a three-day window collide by design; sending the
    // second-oldest wording beats sending nothing.
    const pick = pickVariant({
      variants: [variant('v1'), variant('v2'), variant('v3')],
      language: 'vi',
      variables,
      daysSinceLastUse: new Map([
        ['v1', 1],
        ['v2', 2],
        ['v3', 3],
      ]),
      random: always,
    });
    expect(pick?.variant.key).toBe('v2');
  });

  it('sends something even when all wordings are also inside the relaxed window', () => {
    const pick = pickVariant({
      variants: [variant('v1'), variant('v2')],
      language: 'vi',
      variables,
      daysSinceLastUse: new Map([
        ['v1', 1],
        ['v2', 1],
      ]),
      random: always,
    });
    expect(pick?.variant.key).toBe('v1');
  });

  it('falls back to English for a locale the wording has no copy for', () => {
    const pick = pickVariant({
      variants: [variant('v1')],
      language: 'ko',
      variables,
      random: always,
    });
    expect(pick?.copy.title).toBe('title v1 en');
  });

  it('returns null when nothing is renderable', () => {
    expect(
      pickVariant({
        variants: [{ key: 'v1', copies: { vi: { title: '   ', body: 'x' } } }],
        language: 'vi',
        variables,
        random: always,
      }),
    ).toBeNull();
    expect(
      pickVariant({ variants: [], language: 'vi', variables, random: always }),
    ).toBeNull();
  });

  it('stays in range for a random of 1', () => {
    const pick = pickVariant({
      variants: [variant('v1'), variant('v2')],
      language: 'vi',
      variables,
      random: () => 1,
    });
    expect(pick?.variant.key).toBe('v2');
  });
});

describe('variantCooldownMap', () => {
  const sent = (localDate: string, variantKey: string) => ({
    localDate,
    status: NotificationLogStatus.SENT,
    meta: { variantKey },
  });

  it('measures each wording from its most recent send', () => {
    const map = variantCooldownMap(
      [sent('2026-08-01', 'v1'), sent('2026-08-03', 'v1'), sent('2026-08-02', 'v2')],
      '2026-08-04',
    );
    expect(map.get('v1')).toBe(1);
    expect(map.get('v2')).toBe(2);
  });

  it('ignores rows the phone never showed', () => {
    const map = variantCooldownMap(
      [
        { localDate: '2026-08-03', status: NotificationLogStatus.FAILED, meta: { variantKey: 'v1' } },
        { localDate: '2026-08-03', status: NotificationLogStatus.SKIPPED, meta: { variantKey: 'v2' } },
        { localDate: '2026-08-03', status: NotificationLogStatus.SENT, meta: {} },
      ],
      '2026-08-04',
    );
    expect(map.size).toBe(0);
  });
});

describe('shiftLocalDate', () => {
  it('walks back across a month boundary', () => {
    expect(shiftLocalDate('2026-08-02', -3)).toBe('2026-07-30');
  });

  it('returns the input unchanged when it is not a local date', () => {
    expect(shiftLocalDate('not-a-date', -3)).toBe('not-a-date');
  });
});
