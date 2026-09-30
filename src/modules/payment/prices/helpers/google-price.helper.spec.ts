import { mapGoogleSubscriptionPricesResponse } from './google-price.helper';

describe('mapGoogleSubscriptionPricesResponse', () => {
  it('converts units + nanos into a decimal customerPrice per regionalConfig', () => {
    const response = {
      basePlans: [
        {
          regionalConfigs: [
            {
              regionCode: 'US',
              price: { currencyCode: 'USD', units: '9', nanos: 990000000 },
            },
            {
              regionCode: 'VN',
              price: { currencyCode: 'VND', units: '229000', nanos: 0 },
            },
          ],
        },
      ],
    };

    expect(mapGoogleSubscriptionPricesResponse(response)).toEqual([
      { territory: 'US', currency: 'USD', customerPrice: 9.99 },
      { territory: 'VN', currency: 'VND', customerPrice: 229000 },
    ]);
  });

  it('folds regionalConfigs from every basePlan into one row set', () => {
    const response = {
      basePlans: [
        {
          regionalConfigs: [
            {
              regionCode: 'US',
              price: { currencyCode: 'USD', units: '4', nanos: 990000000 },
            },
          ],
        },
        {
          regionalConfigs: [
            {
              regionCode: 'AU',
              price: { currencyCode: 'AUD', units: '7', nanos: 990000000 },
            },
          ],
        },
      ],
    };

    expect(mapGoogleSubscriptionPricesResponse(response)).toEqual([
      { territory: 'US', currency: 'USD', customerPrice: 4.99 },
      { territory: 'AU', currency: 'AUD', customerPrice: 7.99 },
    ]);
  });

  it('skips a regionalConfig missing its price or regionCode', () => {
    const response = {
      basePlans: [
        {
          regionalConfigs: [
            { regionCode: 'US' }, // no price
            { price: { currencyCode: 'USD', units: '1', nanos: 0 } }, // no regionCode
          ],
        },
      ],
    };

    expect(mapGoogleSubscriptionPricesResponse(response)).toEqual([]);
  });

  it('returns an empty array when there are no basePlans', () => {
    expect(mapGoogleSubscriptionPricesResponse({})).toEqual([]);
  });
});
