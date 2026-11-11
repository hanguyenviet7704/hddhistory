import axios from 'axios';

import {
  fetchAppleTerritoryPrices,
  mapAppleSubscriptionPricesPage,
} from './apple-price.helper';

jest.mock('axios');
// The token signing itself is a thin wrapper around `jsonwebtoken` (not
// exercised here); stub it out so these tests focus on the ASC call
// sequence and the response -> rows mapping.
jest.mock('./apple-asc-token', () => ({
  getAppleAscApiToken: jest.fn(() => 'fake-asc-token'),
}));

const mockedGet = axios.get as jest.Mock;

describe('mapAppleSubscriptionPricesPage', () => {
  it('maps data[] rows to territory prices, resolving territory + subscriptionPricePoint from included[] (verified fixture values)', () => {
    const page = {
      data: [
        {
          relationships: {
            territory: { data: { id: 'AUS' } },
            subscriptionPricePoint: { data: { id: 'pp-aus' } },
          },
        },
        {
          relationships: {
            territory: { data: { id: 'AUT' } },
            subscriptionPricePoint: { data: { id: 'pp-aut' } },
          },
        },
      ],
      included: [
        { type: 'territories', id: 'AUS', attributes: { currency: 'AUD' } },
        { type: 'territories', id: 'AUT', attributes: { currency: 'EUR' } },
        {
          type: 'subscriptionPricePoints',
          id: 'pp-aus',
          attributes: { customerPrice: '22.99' },
        },
        {
          type: 'subscriptionPricePoints',
          id: 'pp-aut',
          attributes: { customerPrice: '14.99' },
        },
      ],
    };

    expect(mapAppleSubscriptionPricesPage(page)).toEqual([
      { territory: 'AUS', currency: 'AUD', customerPrice: 22.99 },
      { territory: 'AUT', currency: 'EUR', customerPrice: 14.99 },
    ]);
  });

  it('skips a row missing its territory or price point relationship', () => {
    const page = {
      data: [
        { relationships: {} },
        {
          relationships: {
            territory: { data: { id: 'USA' } },
            // no subscriptionPricePoint relationship
          },
        },
      ],
      included: [
        { type: 'territories', id: 'USA', attributes: { currency: 'USD' } },
      ],
    };

    expect(mapAppleSubscriptionPricesPage(page)).toEqual([]);
  });

  it('skips a row whose price point/territory id is not present in included[]', () => {
    const page = {
      data: [
        {
          relationships: {
            territory: { data: { id: 'VNM' } },
            subscriptionPricePoint: { data: { id: 'pp-missing' } },
          },
        },
      ],
      included: [],
    };

    expect(mapAppleSubscriptionPricesPage(page)).toEqual([]);
  });

  it('returns an empty array for an empty/missing page', () => {
    expect(mapAppleSubscriptionPricesPage({})).toEqual([]);
  });
});

describe('fetchAppleTerritoryPrices', () => {
  const configService: any = { getAppleBundleId: 'com.hddhistory.app' };

  beforeEach(() => {
    jest.clearAllMocks();
  });

  it('walks apps -> subscriptionGroups -> subscriptions -> prices and maps the response', async () => {
    mockedGet.mockImplementation((url: string) => {
      if (url.endsWith('/apps')) {
        return Promise.resolve({ data: { data: [{ id: 'app-1' }] } });
      }
      if (url === 'https://api.appstoreconnect.apple.com/v1/apps/app-1/subscriptionGroups') {
        return Promise.resolve({ data: { data: [{ id: 'group-1' }] } });
      }
      if (
        url ===
        'https://api.appstoreconnect.apple.com/v1/subscriptionGroups/group-1/subscriptions'
      ) {
        return Promise.resolve({
          data: {
            data: [
              {
                id: 'sub-internal-1',
                attributes: { productId: 'meup_sub_1y_30off' },
              },
            ],
          },
        });
      }
      if (
        url ===
        'https://api.appstoreconnect.apple.com/v1/subscriptions/sub-internal-1/prices'
      ) {
        return Promise.resolve({
          data: {
            data: [
              {
                relationships: {
                  territory: { data: { id: 'AUS' } },
                  subscriptionPricePoint: { data: { id: 'pp-aus' } },
                },
              },
            ],
            included: [
              {
                type: 'territories',
                id: 'AUS',
                attributes: { currency: 'AUD' },
              },
              {
                type: 'subscriptionPricePoints',
                id: 'pp-aus',
                attributes: { customerPrice: '22.99' },
              },
            ],
            links: {},
          },
        });
      }
      throw new Error(`Unexpected URL in test: ${url}`);
    });

    const rows = await fetchAppleTerritoryPrices(
      'meup_sub_1y_30off',
      configService,
    );

    expect(rows).toEqual([
      { territory: 'AUS', currency: 'AUD', customerPrice: 22.99 },
    ]);
    expect(mockedGet).toHaveBeenCalledWith(
      'https://api.appstoreconnect.apple.com/v1/apps',
      expect.objectContaining({
        params: { 'filter[bundleId]': 'com.hddhistory.app' },
      }),
    );
  });

  it('follows links.next to collect every page of territories', async () => {
    mockedGet
      .mockResolvedValueOnce({ data: { data: [{ id: 'app-1' }] } }) // apps
      .mockResolvedValueOnce({ data: { data: [{ id: 'group-1' }] } }) // groups
      .mockResolvedValueOnce({
        data: {
          data: [
            {
              id: 'sub-internal-1',
              attributes: { productId: 'meup_sub_1y_30off' },
            },
          ],
        },
      }) // subscriptions
      .mockResolvedValueOnce({
        data: {
          data: [
            {
              relationships: {
                territory: { data: { id: 'AUS' } },
                subscriptionPricePoint: { data: { id: 'pp-aus' } },
              },
            },
          ],
          included: [
            { type: 'territories', id: 'AUS', attributes: { currency: 'AUD' } },
            {
              type: 'subscriptionPricePoints',
              id: 'pp-aus',
              attributes: { customerPrice: '22.99' },
            },
          ],
          links: { next: 'https://api.appstoreconnect.apple.com/v1/subscriptions/sub-internal-1/prices?cursor=page2' },
        },
      }) // prices page 1
      .mockResolvedValueOnce({
        data: {
          data: [
            {
              relationships: {
                territory: { data: { id: 'AUT' } },
                subscriptionPricePoint: { data: { id: 'pp-aut' } },
              },
            },
          ],
          included: [
            { type: 'territories', id: 'AUT', attributes: { currency: 'EUR' } },
            {
              type: 'subscriptionPricePoints',
              id: 'pp-aut',
              attributes: { customerPrice: '14.99' },
            },
          ],
          links: {},
        },
      }); // prices page 2 (final)

    const rows = await fetchAppleTerritoryPrices(
      'meup_sub_1y_30off',
      configService,
    );

    expect(rows).toEqual([
      { territory: 'AUS', currency: 'AUD', customerPrice: 22.99 },
      { territory: 'AUT', currency: 'EUR', customerPrice: 14.99 },
    ]);
    expect(mockedGet).toHaveBeenCalledTimes(5);
  });

  it('throws when the bundleId has no matching App Store Connect app', async () => {
    mockedGet.mockResolvedValueOnce({ data: { data: [] } });

    await expect(
      fetchAppleTerritoryPrices('meup_sub_1y_30off', configService),
    ).rejects.toThrow(/No App Store Connect app found/);
  });

  it('throws when the SKU is not registered in any subscription group', async () => {
    mockedGet
      .mockResolvedValueOnce({ data: { data: [{ id: 'app-1' }] } }) // apps
      .mockResolvedValueOnce({ data: { data: [{ id: 'group-1' }] } }) // groups
      .mockResolvedValueOnce({ data: { data: [] } }); // subscriptions: no match

    await expect(
      fetchAppleTerritoryPrices('unknown_sku', configService),
    ).rejects.toThrow(/was not found in any App Store Connect subscription group/);
  });
});
