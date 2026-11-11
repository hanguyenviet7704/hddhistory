import { PaymentPlatform } from '../../enum/payment.enum';

export interface IVoucher {
  id: string;
  code: string;
  owner?: string;
  discountPercent?: number;
  validFrom?: Date;
  validTo?: Date;
  maxUses?: number;
  usedCount: number;
  perUserLimit?: number;
  countries?: string[];
  isActive: boolean;
}

export interface IVoucherProductMapping {
  id: string;
  voucherId: string;
  platform: PaymentPlatform;
  baseProductId: string;
  targetProductId: string;
}

export interface IVoucherValidateProduct {
  baseProductId: string;
  targetProductId: string;
}

/**
 * `not_found` / `expired` / `exhausted` / `not_applicable` are the original
 * four and keep their meaning. The last two arrived with the affiliate
 * integration.
 *
 * The Flutter enum declares `@JsonKey(unknownEnumValue: unknown)`, so a build
 * that predates these two degrades to the generic promo-code error rather than
 * failing to parse -- which is why the server can ship them without waiting on
 * an app release.
 *
 * Note that `expired` and `exhausted` are no longer produced by `validate`:
 * expiry and usage limits live on the affiliate side now, and their API
 * collapses both into a plain 404. They stay in the union because older
 * clients still map them and the affiliate contract may grow the distinction
 * back.
 */
export type VoucherValidateReason =
  | 'not_found'
  | 'expired'
  | 'exhausted'
  | 'not_applicable'
  /** The code is real, but the sale already running is as good or better, so
   * applying it would not lower the price. Per the affiliate spec the code is
   * deliberately NOT applied in this case. */
  | 'not_better'
  /** The affiliate voucher service timed out, errored, or rejected our
   * request. Distinct from `not_found` so this never reads as "bad code". */
  | 'unavailable';

export interface IVoucherValidateResult {
  valid: boolean;
  reason?: VoucherValidateReason;
  code?: string;
  discountPercent?: number;
  products?: IVoucherValidateProduct[];
}
