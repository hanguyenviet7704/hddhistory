import { PaymentPlatform } from "../../enum/payment.enum";

/**
 * One synced, staff-visible territory price row for a SKU.
 *
 * READ-ONLY. These rows are populated only by a store sync (Apple App Store
 * Connect / Google Play Developer API) and must never be presented as
 * editable -- the app always reads the real localized price from
 * StoreKit/Play at purchase time, so this table can never be the source of
 * truth for what a user is charged.
 */
export interface IProductPrice {
  id: string;
  productId: string;
  platform: PaymentPlatform;
  territory: string;
  currency: string;
  customerPrice: number;
  source: PaymentPlatform;
  syncedAt: string;
  createdAt?: string;
  updatedAt?: string;
}

export interface IProductPriceQuery {
  productId?: string;
  platform?: PaymentPlatform;
  /**
   * Comma-separated territory codes to restrict the result to (both alpha-2
   * and alpha-3 forms, since Apple and Google disagree on the format -- see
   * `pages/payments/marketTerritoryMap.ts`). Omitted = every territory.
   */
  territories?: string;
}

export interface IProductPriceSyncPayload {
  platform?: PaymentPlatform;
  productId?: string;
}

export interface IPlatformSyncResult {
  synced: number;
  failed: number;
  skippedReason?: string;
}

export interface IProductPriceSyncResult {
  apple: IPlatformSyncResult;
  google: IPlatformSyncResult;
}
