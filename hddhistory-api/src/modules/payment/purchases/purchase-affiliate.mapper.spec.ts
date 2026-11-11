import { Purchase } from './entities/purchase.entity';
import { mapPurchaseToAffiliateOrder } from './purchase-affiliate.mapper';
import { PaymentPlatform, PurchaseStatus } from '../enum/payment.enum';

function makePurchase(overrides: Partial<Purchase> = {}): Purchase {
  return {
    userId: 'user-1',
    userName: 'Jane Doe',
    userEmail: 'jane@example.com',
    platform: PaymentPlatform.APPLE,
    productId: 'meup_sub_1m_70off',
    orderId: '2000000123456789',
    status: PurchaseStatus.PAID,
    purchaseTime: new Date('2026-01-01T00:00:00.000Z'),
    rawPrice: 2.99,
    currency: 'USD',
    country: 'VN',
    language: 'vi',
    voucherCode: 'SUMMER50',
    voucherDiscountPercent: 50,
    ...overrides,
  } as Purchase;
}

describe('mapPurchaseToAffiliateOrder', () => {
  it('maps every field per the external contract when a voucher was applied', () => {
    const purchase = makePurchase();

    const order = mapPurchaseToAffiliateOrder(purchase, '1 Month -70%');

    expect(order).toEqual({
      code: 'SUMMER50',
      discount: 50,
      package_key: 'meup_sub_1m_70off',
      package: '1 Month -70%',
      status: 1,
      country: 'VN',
      language: 'vi',
      order_date_ms: new Date('2026-01-01T00:00:00.000Z').getTime(),
      order_id: '2000000123456789',
      user_id: 'user-1',
      email: 'jane@example.com',
      user_name: 'Jane Doe',
      user_platform: 'ios',
      payment_platform: 'apple',
      price: 2.99,
      currency: 'USD',
    });
  });

  it('defaults discount to 0 and code/package to null when no voucher was applied', () => {
    const purchase = makePurchase({
      voucherCode: undefined,
      voucherDiscountPercent: undefined,
    });

    const order = mapPurchaseToAffiliateOrder(purchase, null);

    expect(order.code).toBeNull();
    expect(order.discount).toBe(0);
    expect(order.package).toBeNull();
  });

  it('maps status to 0 for any non-paid status (e.g. refunded)', () => {
    const purchase = makePurchase({ status: PurchaseStatus.REFUNDED });

    expect(mapPurchaseToAffiliateOrder(purchase).status).toBe(0);
  });

  it('maps status to 0 for pending purchases too', () => {
    const purchase = makePurchase({ status: PurchaseStatus.PENDING });

    expect(mapPurchaseToAffiliateOrder(purchase).status).toBe(0);
  });

  it('maps apple -> ios / google -> android for user_platform, and passes payment_platform through as-is', () => {
    const applePurchase = makePurchase({ platform: PaymentPlatform.APPLE });
    const googlePurchase = makePurchase({ platform: PaymentPlatform.GOOGLE });

    expect(mapPurchaseToAffiliateOrder(applePurchase).user_platform).toBe('ios');
    expect(mapPurchaseToAffiliateOrder(applePurchase).payment_platform).toBe(
      'apple',
    );
    expect(mapPurchaseToAffiliateOrder(googlePurchase).user_platform).toBe(
      'android',
    );
    expect(mapPurchaseToAffiliateOrder(googlePurchase).payment_platform).toBe(
      'google',
    );
  });

  it('maps a missing purchaseTime to a null order_date_ms', () => {
    const purchase = makePurchase({ purchaseTime: undefined });

    expect(mapPurchaseToAffiliateOrder(purchase).order_date_ms).toBeNull();
  });

  it('maps missing country/language/orderId/email/userName/price/currency to null', () => {
    const purchase = makePurchase({
      country: undefined,
      language: undefined,
      orderId: undefined,
      userEmail: undefined,
      userName: undefined,
      rawPrice: undefined,
      currency: undefined,
    });

    const order = mapPurchaseToAffiliateOrder(purchase);

    expect(order.country).toBeNull();
    expect(order.language).toBeNull();
    expect(order.order_id).toBeNull();
    expect(order.email).toBeNull();
    expect(order.user_name).toBeNull();
    expect(order.price).toBeNull();
    expect(order.currency).toBeNull();
  });

  it('falls back package to null when no product title is supplied', () => {
    const purchase = makePurchase();

    expect(mapPurchaseToAffiliateOrder(purchase).package).toBeNull();
  });

  it('reports the entered code when it matched no voucher, with no discount', () => {
    const purchase = makePurchase({
      voucherCode: undefined,
      voucherDiscountPercent: undefined,
      enteredCode: 'HDDHISTORYTES',
    });

    const order = mapPurchaseToAffiliateOrder(purchase);

    expect(order.code).toBe('HDDHISTORYTES');
    expect(order.discount).toBe(0);
  });

  it('prefers the redeemed voucher over the entered code', () => {
    const purchase = makePurchase({ enteredCode: 'typo-then-fixed' });

    expect(mapPurchaseToAffiliateOrder(purchase).code).toBe('SUMMER50');
  });

  it("falls back to the package's salePercent when the voucher carries no percent", () => {
    // The common shape on prod: a swap voucher (base SKU -> cheaper SKU) with
    // an empty discount_percent, sold as a 50%-off package.
    const purchase = makePurchase({
      voucherCode: 'AFF50',
      voucherDiscountPercent: undefined,
      productId: 'meup_sub_1y_50off',
    });

    const order = mapPurchaseToAffiliateOrder(purchase, 'Yearly (sale 50%)', 50);

    expect(order.code).toBe('AFF50');
    expect(order.discount).toBe(50);
  });

  it("prefers the voucher's own percent over the package's", () => {
    const purchase = makePurchase({ voucherDiscountPercent: 20 });

    expect(mapPurchaseToAffiliateOrder(purchase, 'Yearly', 50).discount).toBe(20);
  });

  it('reports 0 when neither the voucher nor the package is discounted', () => {
    const purchase = makePurchase({
      voucherDiscountPercent: undefined,
      productId: 'meup_sub_1y',
    });

    expect(mapPurchaseToAffiliateOrder(purchase, 'Yearly', undefined).discount).toBe(0);
  });

  it('reports no code when the buyer entered none', () => {
    const purchase = makePurchase({
      voucherCode: undefined,
      voucherDiscountPercent: undefined,
      enteredCode: undefined,
    });

    const order = mapPurchaseToAffiliateOrder(purchase);

    expect(order.code).toBeNull();
    expect(order.discount).toBe(0);
  });
});
