/**
 * ISO-3166 alpha-2 codes for the country picker on the Home banner page.
 *
 * Not the full 249-entry list on purpose. A campaign targets markets we
 * actually operate in or plausibly would, and a picker holding every country on
 * earth makes finding Vietnam slower, not more powerful. `MARKETS` leads with
 * the ones this product cares about; the rest of Asia and the large Western
 * markets follow for the occasional campaign that reaches further.
 *
 * The API accepts ANY well-formed alpha-2 code, so nothing here limits what can
 * be stored — this list only decides what is one click away.
 */
export interface CountryOption {
  code: string;
  name: string;
}

export const COUNTRY_OPTIONS: CountryOption[] = [
  // Primary markets.
  { code: "VN", name: "Vietnam" },
  { code: "JP", name: "Japan" },
  { code: "KR", name: "South Korea" },
  { code: "CN", name: "China" },
  { code: "TW", name: "Taiwan" },
  { code: "HK", name: "Hong Kong" },

  // Rest of Asia-Pacific.
  { code: "TH", name: "Thailand" },
  { code: "ID", name: "Indonesia" },
  { code: "MY", name: "Malaysia" },
  { code: "SG", name: "Singapore" },
  { code: "PH", name: "Philippines" },
  { code: "KH", name: "Cambodia" },
  { code: "LA", name: "Laos" },
  { code: "MM", name: "Myanmar" },
  { code: "IN", name: "India" },
  { code: "AU", name: "Australia" },
  { code: "NZ", name: "New Zealand" },

  // Where the diaspora and the large paying markets are.
  { code: "US", name: "United States" },
  { code: "CA", name: "Canada" },
  { code: "GB", name: "United Kingdom" },
  { code: "DE", name: "Germany" },
  { code: "FR", name: "France" },
  { code: "NL", name: "Netherlands" },
  { code: "CZ", name: "Czechia" },
  { code: "PL", name: "Poland" },
  { code: "RU", name: "Russia" },
  { code: "AE", name: "United Arab Emirates" },
];

const BY_CODE = new Map(COUNTRY_OPTIONS.map((c) => [c.code, c]));

/**
 * Turn a stored code into something to display.
 *
 * Falls back to the bare code for anything outside the curated list — a code
 * saved before an entry was added, or one typed straight into the API. Showing
 * `ZA` beats showing nothing and beats dropping it from the chips entirely,
 * which would make a saved value look lost.
 */
export function countryLabel(code: string): string {
  return BY_CODE.get(code)?.name ?? code;
}
