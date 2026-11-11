import { buildPriceSnapshot } from './store-utils';
import { PaymentCurrency } from '../enum/payment.enum';
import { Product } from '../products/entitys/product.entity';

function makeProduct(overrides: Partial<Product> = {}): Product {
  return {
    rawPrice: 9.99,
    salePrice: 2.99,
    currency: PaymentCurrency.USD,
    price: undefined,
    ...overrides,
  } as Product;
}

describe('buildPriceSnapshot', () => {
  it('takes both amount and currency from the store when the store supplies both', () => {
    const product = makeProduct();

    const snapshot = buildPriceSnapshot(product, {
      rawPrice: 75000,
      currency: 'VND',
    });

    expect(snapshot.rawPrice).toBe(75000);
    expect(snapshot.currency).toBe('VND');
    expect(snapshot.price).toBe('VND 75000');
  });

  it('takes both amount and currency from the product row when the store supplies neither', () => {
    const product = makeProduct({
      salePrice: 2.99,
      currency: PaymentCurrency.USD,
    });

    const snapshot = buildPriceSnapshot(product, undefined);

    expect(snapshot.rawPrice).toBe(2.99);
    expect(snapshot.currency).toBe(PaymentCurrency.USD);
    expect(snapshot.price).toBe('USD 2.99');
  });

  it('does NOT mix a store currency with the product amount when the store supplies currency but no amount (regression: VND 2.99 bug)', () => {
    // This is exactly the production bug: Apple's verifyAppleTransaction used
    // to return `currency: 'VND'` (the buyer's real storefront) with no
    // rawPrice at all, while the product row is a $2.99 USD product. The fix
    // must fall back to the PRODUCT's currency too, not just its amount.
    const product = makeProduct({
      salePrice: 2.99,
      currency: PaymentCurrency.USD,
    });

    const snapshot = buildPriceSnapshot(product, {
      currency: 'VND',
      rawPrice: undefined,
    });

    expect(snapshot.rawPrice).toBe(2.99);
    expect(snapshot.currency).toBe(PaymentCurrency.USD);
    expect(snapshot.price).toBe('USD 2.99');
    // The regression produced this exact wrong pair -- make sure it's gone.
    expect(snapshot).not.toEqual(
      expect.objectContaining({ currency: 'VND', rawPrice: 2.99 }),
    );
  });

  it('does NOT label a store amount with the product currency when the store omits one (regression: 9.99 VND)', () => {
    // The mirror of the case above, and the one still reaching production on
    // 2026-08-05: Apple reported the charged amount but no currency, and the
    // product row is priced in VND, so a $9.99 charge was stored as 9.99 VND.
    const product = makeProduct({
      salePrice: undefined,
      rawPrice: 299000,
      currency: PaymentCurrency.VND,
    });

    const snapshot = buildPriceSnapshot(product, { rawPrice: 9.99 });

    expect(snapshot.rawPrice).toBe(9.99);
    expect(snapshot.currency).toBeUndefined();
    expect(snapshot).not.toEqual(
      expect.objectContaining({ currency: PaymentCurrency.VND, rawPrice: 9.99 }),
    );
  });

  it('falls back to product.rawPrice when there is no salePrice, still paired with product.currency', () => {
    const product = makeProduct({
      salePrice: undefined,
      rawPrice: 9.99,
      currency: PaymentCurrency.USD,
    });

    const snapshot = buildPriceSnapshot(product, { currency: 'VND' });

    expect(snapshot.rawPrice).toBe(9.99);
    expect(snapshot.currency).toBe(PaymentCurrency.USD);
  });
});
