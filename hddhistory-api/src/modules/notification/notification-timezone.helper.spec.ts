import {
  canonicalTimeZone,
  groupStoredZonesByCanonical,
  storedZonesForCanonical,
} from './notification-timezone.helper';

describe('canonicalTimeZone', () => {
  it('folds the modern spelling onto the same name ICU enumerates', () => {
    // The bug this whole helper exists for: ICU lists `Asia/Saigon`, phones send
    // `Asia/Ho_Chi_Minh`, and a raw string compare never matched.
    expect(canonicalTimeZone('Asia/Ho_Chi_Minh')).toBe(
      canonicalTimeZone('Asia/Saigon'),
    );
  });

  it('folds the other renamed zones the same way', () => {
    expect(canonicalTimeZone('Asia/Kolkata')).toBe(
      canonicalTimeZone('Asia/Calcutta'),
    );
    expect(canonicalTimeZone('Europe/Kyiv')).toBe(
      canonicalTimeZone('Europe/Kiev'),
    );
  });

  it('returns null for a zone ICU does not know, rather than throwing', () => {
    expect(canonicalTimeZone('Mars/Olympus_Mons')).toBeNull();
    expect(canonicalTimeZone('')).toBeNull();
  });

  it('agrees with what supportedValuesOf enumerates', () => {
    // Guards the assumption the scheduler leans on: every zone in the list is
    // already its own canonical form, so only STORED values need folding.
    // Cast because the repo's TS lib target predates `supportedValuesOf`, which
    // is also why `NotificationDispatchService` reaches for it the same way.
    const zones = (
      Intl as unknown as { supportedValuesOf: (key: string) => string[] }
    ).supportedValuesOf('timeZone');
    const sample = zones.slice(0, 40);
    for (const zone of sample) expect(canonicalTimeZone(zone)).toBe(zone);
  });
});

describe('groupStoredZonesByCanonical', () => {
  it('groups differing spellings of one zone together', () => {
    const grouped = groupStoredZonesByCanonical([
      'Asia/Ho_Chi_Minh',
      'Asia/Saigon',
      'Asia/Tokyo',
    ]);

    const vnKey = canonicalTimeZone('Asia/Saigon') as string;
    expect(grouped.get(vnKey)?.sort()).toEqual([
      'Asia/Ho_Chi_Minh',
      'Asia/Saigon',
    ]);
    expect(grouped.get('Asia/Tokyo')).toEqual(['Asia/Tokyo']);
  });

  it('drops values ICU cannot resolve instead of poisoning the map', () => {
    const grouped = groupStoredZonesByCanonical(['nonsense', 'Asia/Tokyo']);
    expect([...grouped.keys()]).toEqual(['Asia/Tokyo']);
  });

  it('does not duplicate a spelling stored by many users', () => {
    const grouped = groupStoredZonesByCanonical([
      'Asia/Ho_Chi_Minh',
      'Asia/Ho_Chi_Minh',
    ]);
    const vnKey = canonicalTimeZone('Asia/Saigon') as string;
    expect(grouped.get(vnKey)).toEqual(['Asia/Ho_Chi_Minh']);
  });
});

describe('storedZonesForCanonical', () => {
  it('expands a due canonical zone into every stored spelling of it', () => {
    const grouped = groupStoredZonesByCanonical(['Asia/Ho_Chi_Minh']);
    const vnKey = canonicalTimeZone('Asia/Saigon') as string;

    const zones = storedZonesForCanonical([vnKey], grouped);

    // Both, so the query matches users either way round.
    expect(zones).toContain('Asia/Ho_Chi_Minh');
    expect(zones).toContain(vnKey);
  });

  it('keeps the canonical name even when nobody has it stored', () => {
    const zones = storedZonesForCanonical(['Asia/Tokyo'], new Map());
    expect(zones).toEqual(['Asia/Tokyo']);
  });

  it('returns nothing when no zone is due', () => {
    const grouped = groupStoredZonesByCanonical(['Asia/Ho_Chi_Minh']);
    expect(storedZonesForCanonical([], grouped)).toEqual([]);
  });
});
