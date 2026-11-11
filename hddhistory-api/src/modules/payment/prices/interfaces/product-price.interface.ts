/**
 * One territory row returned by a store adapter, before it's persisted.
 * `customerPrice` is the raw numeric amount in the major currency unit
 * (e.g. 22.99), already converted from whatever unit the store used
 * (Apple: decimal string; Google: units + nanos).
 */
export interface IStoreTerritoryPrice {
  territory: string;
  currency: string;
  customerPrice: number;
}

export interface IPlatformSyncResult {
  synced: number;
  failed: number;
  /**
   * SKUs the store has no price endpoint for -- counted apart from `failed` so
   * an expected non-match (a one-time IAP, which is not in a subscription
   * group) never looks like a broken sync.
   */
  skippedProducts?: number;
  skippedReason?: string;
}

export interface ISyncPricesResult {
  apple: IPlatformSyncResult;
  google: IPlatformSyncResult;
}
