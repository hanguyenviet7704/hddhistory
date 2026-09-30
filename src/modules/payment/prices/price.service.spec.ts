import { fetchAppleTerritoryPrices } from './helpers/apple-price.helper';
import { fetchGoogleTerritoryPrices } from './helpers/google-price.helper';
import { PriceService } from './price.service';
import { PaymentPlatform } from '../enum/payment.enum';

jest.mock('./helpers/apple-price.helper');
jest.mock('./helpers/google-price.helper');

const mockedFetchApple = fetchAppleTerritoryPrices as jest.Mock;
const mockedFetchGoogle = fetchGoogleTerritoryPrices as jest.Mock;

function makeProduct(overrides: Record<string, any> = {}) {
  return {
    productId: 'meup_sub_1y_30off',
    platform: PaymentPlatform.APPLE,
    isActive: true,
    ...overrides,
  };
}

interface MakeServiceOptions {
  appleProducts?: any[];
  googleProducts?: any[];
  googlePackageName?: string;
}

function makeService(opts: MakeServiceOptions = {}) {
  const productPriceRepository: any = {
    upsertRow: jest.fn().mockResolvedValue(undefined),
  };
  const productRepository: any = {
    findManyForSync: jest.fn().mockImplementation(({ platform }: any) => {
      if (platform === PaymentPlatform.APPLE) {
        return Promise.resolve(opts.appleProducts ?? [makeProduct()]);
      }
      return Promise.resolve(
        opts.googleProducts ?? [
          makeProduct({ platform: PaymentPlatform.GOOGLE }),
        ],
      );
    }),
  };
  const configService: any = {
    getGooglePackageName:
      'googlePackageName' in opts ? opts.googlePackageName : 'com.hddhistory.app',
  };
  const logger: any = { error: jest.fn(), warn: jest.fn(), log: jest.fn() };
  const requestService: any = { user: { id: 'admin-1' } };

  const service = new PriceService(
    productPriceRepository,
    productRepository,
    configService,
    logger,
    requestService,
  );

  return { service, productPriceRepository, productRepository, logger };
}

describe('PriceService.sync', () => {
  beforeEach(() => {
    jest.clearAllMocks();
  });

  it('persists Apple rows and reports Google as failed/unauthorized, without throwing, when Google returns 401 (never fail the whole sync)', async () => {
    mockedFetchApple.mockResolvedValue([
      { territory: 'AUS', currency: 'AUD', customerPrice: 22.99 },
      { territory: 'AUT', currency: 'EUR', customerPrice: 14.99 },
    ]);
    const unauthorized: any = new Error('Request failed with status code 401');
    unauthorized.response = { status: 401 };
    mockedFetchGoogle.mockRejectedValue(unauthorized);

    const { service, productPriceRepository } = makeService();

    const result = await service.sync({});

    expect(result.apple).toEqual({ synced: 2, failed: 0 });
    expect(result.google.synced).toBe(0);
    expect(result.google.failed).toBe(1);
    expect(result.google.skippedReason).toMatch(/unauthorized/i);

    // The Apple rows were persisted despite the Google failure.
    expect(productPriceRepository.upsertRow).toHaveBeenCalledTimes(2);
    expect(productPriceRepository.upsertRow).toHaveBeenCalledWith(
      expect.objectContaining({
        productId: 'meup_sub_1y_30off',
        platform: PaymentPlatform.APPLE,
        territory: 'AUS',
        source: PaymentPlatform.APPLE,
      }),
      'admin-1',
    );
  });

  it('never throws out of sync() even when both stores fail', async () => {
    mockedFetchApple.mockRejectedValue(new Error('network error'));
    const unauthorized: any = new Error('unauthorized');
    unauthorized.response = { status: 403 };
    mockedFetchGoogle.mockRejectedValue(unauthorized);

    const { service } = makeService();

    await expect(service.sync({})).resolves.toEqual({
      apple: { synced: 0, failed: 1 },
      google: {
        synced: 0,
        failed: 1,
        skippedReason: expect.stringMatching(/unauthorized/i),
      },
    });
  });

  it('skips Google entirely (not "failed") when GOOGLE_PACKAGE_NAME is not configured, and still syncs Apple', async () => {
    mockedFetchApple.mockResolvedValue([
      { territory: 'AUS', currency: 'AUD', customerPrice: 22.99 },
    ]);

    const { service, productPriceRepository } = makeService({
      googlePackageName: undefined,
    });

    const result = await service.sync({});

    expect(result.apple.synced).toBe(1);
    expect(result.google).toEqual({
      synced: 0,
      failed: 0,
      skippedReason: 'GOOGLE_PACKAGE_NAME is not configured',
    });
    expect(mockedFetchGoogle).not.toHaveBeenCalled();
    expect(productPriceRepository.upsertRow).toHaveBeenCalledTimes(1);
  });

  it('marks a platform skipped (not failed) when no products match, without calling the store', async () => {
    const { service } = makeService({ appleProducts: [], googleProducts: [] });

    const result = await service.sync({});

    expect(result.apple).toEqual({
      synced: 0,
      failed: 0,
      skippedReason: 'no matching apple products',
    });
    expect(mockedFetchApple).not.toHaveBeenCalled();
    expect(mockedFetchGoogle).not.toHaveBeenCalled();
  });

  it('excludes the other platform (skippedReason, no store calls) when a platform filter is given', async () => {
    mockedFetchApple.mockResolvedValue([
      { territory: 'AUS', currency: 'AUD', customerPrice: 22.99 },
    ]);

    const { service, productRepository } = makeService();

    const result = await service.sync({ platform: PaymentPlatform.APPLE });

    expect(result.apple.synced).toBe(1);
    expect(result.google).toEqual({
      synced: 0,
      failed: 0,
      skippedReason: 'excluded by platform filter',
    });
    expect(mockedFetchGoogle).not.toHaveBeenCalled();
    expect(productRepository.findManyForSync).toHaveBeenCalledTimes(1);
    expect(productRepository.findManyForSync).toHaveBeenCalledWith({
      platform: PaymentPlatform.APPLE,
      productId: undefined,
      onlyActive: true,
    });
  });

  it('syncs an inactive product when an exact productId is requested (onlyActive turned off)', async () => {
    mockedFetchApple.mockResolvedValue([]);

    const { service, productRepository } = makeService();

    await service.sync({ productId: 'meup_sub_1m_70off' });

    expect(productRepository.findManyForSync).toHaveBeenCalledWith({
      platform: PaymentPlatform.APPLE,
      productId: 'meup_sub_1m_70off',
      onlyActive: false,
    });
  });
});
