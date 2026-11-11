import { PaymentPlatform } from "../../types/enum/payment.enum";

/**
 * Fixed list of markets shown as columns in the regional price matrix.
 *
 * Apple (App Store Connect) and Google (Play Developer API) do not agree on
 * a territory code format: Apple returns ISO 3166-1 ALPHA-3 ("USA", "VNM",
 * "SGP", ...), Google returns ALPHA-2 ("US", "VN", "SG", ...). Price rows are
 * persisted with whatever code the originating store sent, so a single row
 * can never be looked up by "the" territory code -- it depends which
 * platform the row belongs to. Rather than trying to derive one form from
 * the other (they are not always a trivial substring/prefix of each other),
 * every market below carries both forms explicitly.
 *
 * This is the single place that defines which markets appear as matrix
 * columns and in what order -- add/remove/reorder entries here and nothing
 * else needs to change.
 */
export interface IMarketTerritory {
  /** Column header shown to the operator, e.g. "US". */
  label: string;
  /** ISO 3166-1 alpha-3 code, as returned by App Store Connect. */
  apple: string;
  /** ISO 3166-1 alpha-2 code, as returned by Google Play. */
  google: string;
}

export const MARKET_TERRITORIES: IMarketTerritory[] = [
  { label: "SG", apple: "SGP", google: "SG" },
  { label: "US", apple: "USA", google: "US" },
  { label: "VN", apple: "VNM", google: "VN" },
  { label: "DE", apple: "DEU", google: "DE" },
  { label: "TR", apple: "TUR", google: "TR" },
  { label: "KR", apple: "KOR", google: "KR" },
  { label: "RU", apple: "RUS", google: "RU" },
  { label: "JP", apple: "JPN", google: "JP" },
  { label: "TW", apple: "TWN", google: "TW" },
  { label: "AU", apple: "AUS", google: "AU" },
  { label: "GB", apple: "GBR", google: "GB" },
];

/**
 * Returns the store-specific territory code a price row would have been
 * persisted with for a given market + platform. Use this for every cell
 * lookup instead of comparing labels directly -- it keeps the "which code
 * form does this platform use" decision in one place.
 */
export const territoryCodeFor = (
  market: IMarketTerritory,
  platform: PaymentPlatform
): string =>
  platform === PaymentPlatform.APPLE ? market.apple : market.google;

/**
 * Every territory code the matrix can possibly display (both alpha-2 and
 * alpha-3 forms, for every market above), comma-separated and ready for the
 * `territories` query param on GET /payment/product-prices.
 *
 * A single SKU has ~175 synced territory rows per platform; without this the
 * matrix would pull thousands of rows to render a dozen visible columns.
 */
export const MARKET_TERRITORY_PARAM = MARKET_TERRITORIES.flatMap((market) => [
  market.apple,
  market.google,
]).join(",");
