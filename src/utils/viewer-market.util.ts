// Which markets a viewer belongs to, and whether a targeted surface should be
// shown to them. Lives here rather than in one feature module because BOTH the
// Home banner and the Home popup target by market, and two copies of this rule
// would drift the first time one of them gained a signal.

/**
 * Cloudflare's stand-ins for "we could not place this request".
 *
 * `XX` is an unknown or reserved address, `T1` is Tor. Both are treated exactly
 * like a missing header — see [[resolveViewerMarkets]].
 */
const UNRESOLVED_COUNTRIES = new Set(['XX', 'T1']);

// Two LETTERS, not merely two characters. Shared by both the read and the write
// path so a code that survives one is guaranteed to satisfy the other.
const ALPHA2 = /^[A-Z]{2}$/;

/**
 * Countries an app language stands in for.
 *
 * This is what lets country targeting reach a diaspora: a Vietnamese living in
 * Japan has a Japanese IP and often a Japanese device region, but reads the app
 * in Vietnamese — and a Vietnam campaign is meant for them (product call,
 * 2026-08-11).
 *
 * `en` is deliberately absent. It is the app's fallback locale for the whole
 * world, so it stands in for no market: mapping it to US/GB would hand every
 * English-reading user in every country a banner targeted at either.
 */
const LANGUAGE_MARKETS: Record<string, string[]> = {
  vi: ['VN'],
  ja: ['JP'],
  ko: ['KR'],
  zh: ['CN', 'TW', 'HK'],
};

/**
 * Every market this viewer plausibly belongs to -- the union of where they ARE
 * and what they READ.
 *
 * Targeting matches on ANY of these ([[isVisibleInMarkets]]), so the
 * admin's country list means "this market", not "physically inside this
 * border". Three independent signals, none of which is authoritative alone:
 *
 * - `cf-ipcountry`: where the phone is right now. Misses the diaspora entirely.
 * - `x-device-country`: the device region. A Vietnamese abroad usually keeps it
 *   at VN, but it is also the one a fresh phone bought locally reports wrong.
 * - `lang`: the language the reader chose IN the app, mapped through
 *   [[LANGUAGE_MARKETS]]. The strongest signal of "who this campaign is for"
 *   and the only one that survives moving country.
 *
 * The cost of the union is the mirror image of the old behaviour's: a campaign
 * that genuinely means "people inside Vietnam" (a VN-only price, say) will also
 * reach Vietnamese readers abroad. Promotional images only -- nothing here
 * gates content or entitlement.
 */
export function resolveViewerMarkets({
  cfCountry,
  deviceCountry,
  appLanguage,
}: {
  cfCountry?: string;
  deviceCountry?: string;
  appLanguage?: string;
}): string[] {
  const markets = new Set<string>();

  // Both country signals count, not just the winner: the IP places the request
  // and the device region places the person, and a diaspora viewer is the case
  // where the two legitimately disagree.
  for (const candidate of [cfCountry, deviceCountry]) {
    const code = (candidate ?? '').trim().toUpperCase();
    if (ALPHA2.test(code) && !UNRESOLVED_COUNTRIES.has(code)) markets.add(code);
  }

  // `lang` arrives as the app's language code (`vi`), but be tolerant of a full
  // locale (`vi-VN`) in case a client ever sends one.
  const language = (appLanguage ?? '').trim().toLowerCase().split(/[-_]/)[0];
  for (const code of LANGUAGE_MARKETS[language] ?? []) markets.add(code);

  return [...markets];
}

/**
 * Whether a banner targeted at `countries` should be shown to a viewer who
 * belongs to `viewerMarkets` (see [[resolveViewerMarkets]]).
 *
 * An empty list means no targeting at all, so everyone sees it. That is what
 * makes this safe to deploy without a migration: existing config documents have
 * no `countries` field, read back as `[]`, and keep behaving exactly as they did.
 *
 * ANY overlap is enough. A Vietnamese in Japan resolves to `['JP', 'VN']` — the
 * JP from their IP, the VN from reading the app in Vietnamese — and so sees both
 * a Japan campaign and a Vietnam one.
 *
 * A viewer we could place in no market at all is hidden from a TARGETED banner.
 * The admin said "only these countries"; showing it to someone we know nothing
 * about does the opposite. In practice this is now rare, since the app always
 * sends `lang` — it means a viewer with no country signal AND a language that
 * stands in for no market (English). Leaving the list empty is still the way to
 * see a banner locally, where Cloudflare is not in front.
 */
export function isVisibleInMarkets(
  countries: string[] | undefined,
  viewerMarkets: string[],
): boolean {
  if (!countries || countries.length === 0) return true;

  return countries.some(country => viewerMarkets.includes(country));
}

/**
 * Clean up a list of country codes on the way into the database.
 *
 * Uppercased, trimmed, de-duplicated, and anything that is not two letters
 * dropped. Normalising on WRITE rather than on read means the matcher above can
 * be a plain `includes` -- if `'vn'` were allowed to reach Mongo, every read
 * path would have to remember to upper-case, and one that forgot would fail to
 * match with no error to show for it.
 */
export function normalizeCountryCodes(codes: string[] | undefined): string[] {
  if (!codes) return [];

  const seen = new Set<string>();
  for (const raw of codes) {
    const code = String(raw ?? '').trim().toUpperCase();
    if (ALPHA2.test(code)) seen.add(code);
  }

  return [...seen];
}

// Two lowercase LETTERS — the app's locale codes (vi, en, zh, ja, ko). Same
// write/read pairing as ALPHA2: what survives normalisation is exactly what
// the matcher compares against.
const LOCALE2 = /^[a-z]{2}$/;

/**
 * The language this viewer reads the app in, from the `lang` header the app
 * already sends on every request (the same header market resolution taps).
 * Tolerant of a full locale (`vi-VN`); empty when the header is missing or
 * unusable.
 */
export function resolveViewerLanguage(appLanguage?: string): string {
  const language = (appLanguage ?? '').trim().toLowerCase().split(/[-_]/)[0];

  return LOCALE2.test(language) ? language : '';
}

/**
 * Whether a surface targeted at `locales` should be shown to a viewer reading
 * in `viewerLanguage` (see [[resolveViewerLanguage]]).
 *
 * Same contract as [[isVisibleInMarkets]]: an empty list means no targeting,
 * so everyone sees it — which is what lets the field be added to existing
 * config documents without a migration. A viewer whose language we could not
 * read is hidden from a TARGETED surface, exactly like the market rule.
 */
export function isVisibleInLocales(
  locales: string[] | undefined,
  viewerLanguage: string,
): boolean {
  if (!locales || locales.length === 0) return true;

  return Boolean(viewerLanguage) && locales.includes(viewerLanguage);
}

/**
 * Clean up a list of locale codes on the way into the database — the
 * lowercase twin of [[normalizeCountryCodes]], for the same reason: normalise
 * on WRITE so the matcher stays a plain `includes`.
 */
export function normalizeLocaleCodes(codes: string[] | undefined): string[] {
  if (!codes) return [];

  const seen = new Set<string>();
  for (const raw of codes) {
    const code = String(raw ?? '').trim().toLowerCase();
    if (LOCALE2.test(code)) seen.add(code);
  }

  return [...seen];
}
