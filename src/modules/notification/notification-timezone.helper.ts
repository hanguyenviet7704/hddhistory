/**
 * Reconciling the zone names ICU enumerates with the ones devices actually send.
 *
 * `Intl.supportedValuesOf('timeZone')` returns ICU's CANONICAL names, which for
 * several zones are the historical spelling: `Asia/Saigon`, not
 * `Asia/Ho_Chi_Minh`; `Asia/Katmandu`, not `Asia/Kathmandu`; `Asia/Calcutta`,
 * not `Asia/Kolkata`; `Europe/Kiev`, not `Europe/Kyiv`. Phones report the modern
 * spelling — iOS and Android both hand back `Asia/Ho_Chi_Minh`.
 *
 * So the two sides never met: the scheduler decided `Asia/Saigon` was due and
 * queried users for exactly that string, while every Vietnamese user had
 * `Asia/Ho_Chi_Minh` stored. Zones matched, users never did — no candidates, no
 * log row, no error, nothing to see. That is the whole reason scheduled
 * notifications had never once been delivered.
 *
 * Fixed by comparing canonical forms rather than raw strings, in both
 * directions: ICU canonicalises any alias it accepts, so one `Intl` call folds
 * `Asia/Ho_Chi_Minh` and `Asia/Saigon` onto the same key.
 */

/**
 * ICU's canonical name for [zone], or null when ICU does not recognise it at
 * all (a typo, or a zone this build's ICU has never heard of).
 */
export function canonicalTimeZone(zone: string): string | null {
  if (!zone) return null;
  try {
    return new Intl.DateTimeFormat('en', { timeZone: zone }).resolvedOptions()
      .timeZone;
  } catch {
    return null;
  }
}

/**
 * Groups the zone strings actually present in the database by their canonical
 * form, so a canonical zone the scheduler finds due can be turned back into
 * every spelling users have stored.
 *
 * Built from real stored values rather than a hardcoded alias table: the only
 * aliases that matter are the ones devices send, and that set answers itself.
 */
export function groupStoredZonesByCanonical(
  storedZones: string[],
): Map<string, string[]> {
  const byCanonical = new Map<string, string[]>();
  for (const stored of storedZones) {
    const canonical = canonicalTimeZone(stored);
    if (!canonical) continue;
    const existing = byCanonical.get(canonical);
    if (existing) {
      if (!existing.includes(stored)) existing.push(stored);
    } else {
      byCanonical.set(canonical, [stored]);
    }
  }
  return byCanonical;
}

/**
 * Every stored spelling that belongs to one of [canonicalZones].
 *
 * The canonical name itself is included even when nobody has it stored, so a
 * user whose device happens to report the canonical spelling is still matched.
 */
export function storedZonesForCanonical(
  canonicalZones: string[],
  byCanonical: Map<string, string[]>,
): string[] {
  const matched = new Set<string>();
  for (const canonical of canonicalZones) {
    matched.add(canonical);
    for (const stored of byCanonical.get(canonical) ?? []) matched.add(stored);
  }
  return [...matched];
}
