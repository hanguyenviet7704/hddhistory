import {
  AffiliateVoucherFailure,
  AffiliateVoucherPackage,
} from './affiliate/affiliate-voucher.client';
import { VoucherService } from './voucher.service';
import { PaymentPlatform } from '../enum/payment.enum';

const APPLE = PaymentPlatform.APPLE;

/**
 * `validate` makes two judgements the affiliate cannot: whether the SKU they
 * named is really sellable, and which of the SKUs currently on the paywall it
 * should replace. Expiry / usage / per-user / country rules are deliberately
 * NOT tested here -- they moved to the affiliate side.
 */

function product(
  productId: string,
  salePercent = 0,
  compareAtProductId?: string,
) {
  return { productId, salePercent, compareAtProductId } as any;
}

/**
 * The real yearly ladder, as read off `/paywall-config/mobile` and the admin
 * product list: one full-price root plus discounted siblings pointing at it.
 */
const YEARLY_LADDER = [
  product('meup_sub_1y', 0),
  product('meup_sub_1y_20off', 20, 'meup_sub_1y'),
  product('meup_sub_1y_30off', 30, 'meup_sub_1y'),
  product('meup_sub_1y_50off', 50, 'meup_sub_1y'),
];

interface MakeServiceOptions {
  packages?: AffiliateVoucherPackage[];
  failure?: AffiliateVoucherFailure;
  /** Stands in for iap_products; the mocks query it the way the real repo does. */
  catalogue?: any[];
  user?: Record<string, any>;
}

function makeService(opts: MakeServiceOptions = {}) {
  const catalogue = opts.catalogue ?? [];

  const affiliateClient: any = {
    get: jest
      .fn()
      .mockResolvedValue(
        opts.failure
          ? { failure: opts.failure }
          : { packages: opts.packages ?? [] },
      ),
    use: jest.fn().mockResolvedValue(true),
  };
  // Behavioural mocks rather than fixed return values: `findActiveByProductIds`
  // is called twice per validate (targets, then family roots) with different
  // arguments, so a canned answer would make the second call a lie.
  const productRepository: any = {
    findActiveByProductIds: jest.fn((_platform: any, ids: string[]) =>
      Promise.resolve(catalogue.filter((p) => ids.includes(p.productId))),
    ),
    findActiveByCompareAtProductIds: jest.fn((_platform: any, roots: string[]) =>
      Promise.resolve(
        catalogue.filter(
          (p) => p.compareAtProductId && roots.includes(p.compareAtProductId),
        ),
      ),
    ),
  };
  const requestService: any = {
    user: 'user' in opts ? opts.user : { id: 'user-1', email: 'a@b.co' },
  };

  const service = new VoucherService(
    // voucherRepository / mappingRepository back the legacy read-only admin
    // CRUD only; `validate` no longer touches either.
    {} as any,
    {} as any,
    productRepository,
    affiliateClient,
    requestService,
  );

  return { service, affiliateClient, productRepository };
}

const validateApple = (service: VoucherService, code = 'hddhistorytes') =>
  service.validate({ code, platform: APPLE });

const swapTargets = (result: any) =>
  (result.products ?? []).map((p: any) => p.targetProductId);
const swapBases = (result: any) =>
  (result.products ?? []).map((p: any) => p.baseProductId).sort();

describe('VoucherService.validate — affiliate lookup failures', () => {
  it('reports unavailable when the affiliate service is unreachable', async () => {
    const { service } = makeService({ failure: 'unavailable' });

    const result = await validateApple(service);

    expect(result.valid).toBe(false);
    expect(result.reason).toBe('unavailable');
  });

  it('reports not_found for their 404 (unknown code)', async () => {
    const { service } = makeService({ failure: 'not_found' });

    expect((await validateApple(service)).reason).toBe('not_found');
  });

  it('reports not_found when they reject our body (422)', async () => {
    const { service } = makeService({ failure: 'invalid_input' });

    expect((await validateApple(service)).reason).toBe('not_found');
  });

  it('reports not_found when the code exists but discounts nothing', async () => {
    const { service } = makeService({ packages: [] });

    expect((await validateApple(service)).reason).toBe('not_found');
  });

  it('sends the code uppercased, with the caller identity', async () => {
    const { service, affiliateClient } = makeService({
      user: { id: 'user-9', email: 'nine@hddhistory.test' },
    });

    await validateApple(service, '  hddhistorytes ');

    expect(affiliateClient.get).toHaveBeenCalledWith('HDDHISTORYTES', {
      userId: 'user-9',
      email: 'nine@hddhistory.test',
    });
  });
});

describe('VoucherService.validate — shared package-key namespace', () => {
  it('ignores package keys that are not HDDhistory products', async () => {
    // Their response for one product id genuinely mixes app prefixes.
    const { service } = makeService({
      packages: [
        { packageKey: 'jlct1months', discountPercent: 70 },
        { packageKey: 'pre12months', discountPercent: 70 },
      ],
      catalogue: YEARLY_LADDER,
    });

    const result = await validateApple(service);

    expect(result.valid).toBe(false);
    expect(result.reason).toBe('not_applicable');
  });
});

describe('VoucherService.validate — swaps the whole plan family', () => {
  it('offers a swap from every SKU the paywall could be showing', async () => {
    const { service } = makeService({
      packages: [{ packageKey: 'meup_sub_1y_50off', discountPercent: 50 }],
      catalogue: YEARLY_LADDER,
    });

    const result = await validateApple(service);

    expect(result.valid).toBe(true);
    expect(result.discountPercent).toBe(50);
    // Every cohort is covered: full price, the 20% tier and the 30% tier all
    // resolve to the 50% SKU. Covering only one of them would leave the code
    // silently doing nothing for the others.
    expect(swapBases(result)).toEqual([
      'meup_sub_1y',
      'meup_sub_1y_20off',
      'meup_sub_1y_30off',
    ]);
    expect(new Set(swapTargets(result))).toEqual(
      new Set(['meup_sub_1y_50off']),
    );
  });
});

describe('VoucherService.validate — two package keys, one plan', () => {
  // The live payload: code HDDHISTORYTES answers with BOTH meup_sub_1y_50off @50 and
  // meup_sub_1y_30off @30, which sit in the same family.
  const livePackages: AffiliateVoucherPackage[] = [
    { packageKey: 'meup_sub_1y_50off', discountPercent: 50 },
    { packageKey: 'meup_sub_1y_30off', discountPercent: 30 },
  ];

  it('gives every base the deepest discount available', async () => {
    const { service } = makeService({
      packages: livePackages,
      catalogue: YEARLY_LADDER,
    });

    const result = await validateApple(service);

    expect(result.valid).toBe(true);
    // One swap per base -- the client folds these into a Map, so a duplicated
    // base would let the shallower target silently win.
    expect(swapBases(result)).toEqual([
      'meup_sub_1y',
      'meup_sub_1y_20off',
      'meup_sub_1y_30off',
    ]);
    expect(new Set(swapTargets(result))).toEqual(
      new Set(['meup_sub_1y_50off']),
    );
    // Charge and reported percentage must agree.
    expect(result.discountPercent).toBe(50);
  });

  it('does not depend on the order the packages arrive in', async () => {
    const { service } = makeService({
      packages: [...livePackages].reverse(),
      catalogue: YEARLY_LADDER,
    });

    const result = await validateApple(service);

    expect(new Set(swapTargets(result))).toEqual(
      new Set(['meup_sub_1y_50off']),
    );
    expect(result.discountPercent).toBe(50);
  });
});

describe('VoucherService.validate — versus the sale already running', () => {
  it('reports not_better when every base already has a deeper discount', async () => {
    const { service } = makeService({
      packages: [{ packageKey: 'meup_sub_1y_30off', discountPercent: 30 }],
      // Only the 30% and 50% tiers exist here, so the code's own tier is the
      // shallowest thing on offer and has nothing to improve on.
      catalogue: [
        product('meup_sub_1y_30off', 30, 'meup_sub_1y'),
        product('meup_sub_1y_50off', 50, 'meup_sub_1y'),
      ],
    });

    const result = await validateApple(service);

    expect(result.valid).toBe(false);
    expect(result.reason).toBe('not_better');
  });

  it('still applies to the bases it does beat', async () => {
    const { service } = makeService({
      packages: [{ packageKey: 'meup_sub_1y_30off', discountPercent: 30 }],
      catalogue: YEARLY_LADDER,
    });

    const result = await validateApple(service);

    expect(result.valid).toBe(true);
    // Beats full price and the 20% tier; loses to the 50% tier, which is
    // therefore left alone rather than being made more expensive.
    expect(swapBases(result)).toEqual(['meup_sub_1y', 'meup_sub_1y_20off']);
    expect(result.discountPercent).toBe(30);
  });
});

describe('VoucherService.validate — unsellable targets', () => {
  it('refuses a target with no catalogue discount instead of trusting the affiliate', async () => {
    const { service } = makeService({
      // They claim 50% off the FULL-PRICE SKU. Honouring that on their word
      // would swap discounted SKUs for a dearer one and charge more.
      packages: [{ packageKey: 'meup_sub_1y', discountPercent: 50 }],
      catalogue: YEARLY_LADDER,
    });

    const result = await validateApple(service);

    expect(result.valid).toBe(false);
    expect(result.reason).toBe('not_applicable');
  });

  it('reports not_applicable when the named SKU is not an active product', async () => {
    const { service } = makeService({
      packages: [{ packageKey: 'meup_sub_1y_50off', discountPercent: 50 }],
      // 50off has not been created in the catalogue yet.
      catalogue: [
        product('meup_sub_1y', 0),
        product('meup_sub_1y_30off', 30, 'meup_sub_1y'),
      ],
    });

    const result = await validateApple(service);

    expect(result.valid).toBe(false);
    expect(result.reason).toBe('not_applicable');
  });
});

describe('VoucherService.reportRedemption', () => {
  it('reports the charged SKU as the package key', async () => {
    const { service, affiliateClient } = makeService();

    await service.reportRedemption({
      code: 'hddhistorytes',
      productId: 'meup_sub_1y_50off',
      userId: 'user-1',
      email: 'a@b.co',
    });

    expect(affiliateClient.use).toHaveBeenCalledWith({
      code: 'HDDHISTORYTES',
      packageKey: 'meup_sub_1y_50off',
      identity: { userId: 'user-1', email: 'a@b.co' },
    });
  });
});
