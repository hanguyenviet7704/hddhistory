import { AffiliateOrderItem } from './dto/affiliate-order.response';
import { Purchase } from './entities/purchase.entity';
import { PaymentPlatform, PurchaseStatus } from '../enum/payment.enum';

const USER_PLATFORM_BY_PAYMENT_PLATFORM: Record<PaymentPlatform, string> = {
  [PaymentPlatform.APPLE]: 'ios',
  [PaymentPlatform.GOOGLE]: 'android',
};

/**
 * Maps a single `iap_purchases` row (Part 4 columns included) to the
 * affiliate orders API's exact snake_case contract (Part 5). Pure function --
 * no DB/network access -- so it can be unit-tested directly.
 */
export function mapPurchaseToAffiliateOrder(
  purchase: Purchase,
  productTitle?: string | null,
  productSalePercent?: number | null,
): AffiliateOrderItem {
  return {
    // A redeemed voucher first, then whatever the buyer typed. They are the
    // same string when a voucher was applied; the fallback is what makes an
    // affiliate code with no `iap_vouchers` row behind it reportable at all,
    // and it keeps rows written before `entered_code` existed working.
    code: purchase.voucherCode ?? purchase.enteredCode ?? null,
    // The voucher's own percent first, then the PACKAGE's. Most codes discount
    // by swapping the buyer onto a cheaper SKU (`meup_sub_1y` ->
    // `meup_sub_1y_50off`) and leave `iap_vouchers.discount_percent` empty, so
    // reading the voucher alone reported `discount: 0` on genuinely discounted
    // sales -- while the SKU has carried the real number in `salePercent` all
    // along (30/20/50/40/70 across the catalog).
    discount: purchase.voucherDiscountPercent ?? productSalePercent ?? 0,
    package_key: purchase.productId,
    package: productTitle ?? null,
    status: purchase.status === PurchaseStatus.PAID ? 1 : 0,
    country: purchase.country ?? null,
    language: purchase.language ?? null,
    order_date_ms: purchase.purchaseTime
      ? new Date(purchase.purchaseTime).getTime()
      : null,
    order_id: purchase.orderId ?? null,
    user_id: purchase.userId,
    email: purchase.userEmail ?? null,
    user_name: purchase.userName ?? null,
    user_platform:
      USER_PLATFORM_BY_PAYMENT_PLATFORM[purchase.platform] ?? purchase.platform,
    payment_platform: purchase.platform,
    price: purchase.rawPrice ?? null,
    currency: purchase.currency ?? null,
  };
}
