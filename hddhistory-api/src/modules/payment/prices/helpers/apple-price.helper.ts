import axios from 'axios';

import { Configuration } from '@base/config/configuration';

import { getAppleAscApiToken } from './apple-asc-token';
import { IStoreTerritoryPrice } from '../interfaces/product-price.interface';

const ASC_BASE_URL = 'https://api.appstoreconnect.apple.com/v1';

/**
 * Pure mapping of one page of
 * `GET /v1/subscriptions/{id}/prices?include=subscriptionPricePoint,territory`
 * to territory price rows:
 * - `relationships.territory.data.id` on each `data[]` row is the ISO
 *   territory code.
 * - `relationships.subscriptionPricePoint.data.id` resolves against
 *   `included[]` (type `subscriptionPricePoints`) for `attributes.customerPrice`.
 * - the matching `included[]` territory (type `territories`) carries
 *   `attributes.currency`.
 *
 * Split out from the network call so it can be unit-tested against a fixture
 * response with no HTTP/JWT involved.
 */
export function mapAppleSubscriptionPricesPage(page: {
  data?: any[];
  included?: any[];
}): IStoreTerritoryPrice[] {
  const pricePointsById = new Map<string, any>();
  const territoriesById = new Map<string, any>();
  for (const item of page.included ?? []) {
    if (item?.type === 'subscriptionPricePoints') {
      pricePointsById.set(item.id, item);
    }
    if (item?.type === 'territories') {
      territoriesById.set(item.id, item);
    }
  }

  const rows: IStoreTerritoryPrice[] = [];
  for (const row of page.data ?? []) {
    const territoryId = row?.relationships?.territory?.data?.id;
    const pricePointId = row?.relationships?.subscriptionPricePoint?.data?.id;
    if (!territoryId || !pricePointId) continue;

    const territory = territoriesById.get(territoryId);
    const pricePoint = pricePointsById.get(pricePointId);
    const customerPrice = pricePoint?.attributes?.customerPrice;
    const currency = territory?.attributes?.currency;
    if (customerPrice === undefined || customerPrice === null || !currency) {
      continue;
    }

    rows.push({
      territory: territoryId,
      currency,
      customerPrice: Number(customerPrice),
    });
  }
  return rows;
}

async function findAppStoreConnectAppId(
  headers: Record<string, string>,
  bundleId: string,
): Promise<string> {
  const resp = await axios.get(`${ASC_BASE_URL}/apps`, {
    headers,
    params: { 'filter[bundleId]': bundleId },
  });
  const appId = resp.data?.data?.[0]?.id;
  if (!appId) {
    throw new Error(
      `No App Store Connect app found for bundleId "${bundleId}"`,
    );
  }
  return appId;
}

async function findSubscriptionInternalId(
  headers: Record<string, string>,
  appId: string,
  productId: string,
): Promise<string> {
  const groupsResp = await axios.get(
    `${ASC_BASE_URL}/apps/${appId}/subscriptionGroups`,
    { headers },
  );
  const groupIds: string[] = (groupsResp.data?.data ?? []).map(
    (group: any) => group.id,
  );

  for (const groupId of groupIds) {
    const subsResp = await axios.get(
      `${ASC_BASE_URL}/subscriptionGroups/${groupId}/subscriptions`,
      { headers },
    );
    const match = (subsResp.data?.data ?? []).find(
      (sub: any) => sub?.attributes?.productId === productId,
    );
    if (match) return match.id;
  }

  throw new Error(
    `Subscription SKU "${productId}" was not found in any App Store ` +
      'Connect subscription group',
  );
}

/**
 * Full ASC call sequence for one subscription SKU:
 * `apps?filter[bundleId]` -> `subscriptionGroups` -> `subscriptions` ->
 * `subscriptions/{id}/prices`. Follows `links.next` so a SKU with more than
 * one page of territories (limit=200) still returns every row.
 */
export async function fetchAppleTerritoryPrices(
  productId: string,
  configService = new Configuration(),
): Promise<IStoreTerritoryPrice[]> {
  const token = getAppleAscApiToken(configService);
  const headers = { Authorization: `Bearer ${token}` };
  const bundleId = configService.getAppleAscBundleId;

  const appId = await findAppStoreConnectAppId(headers, bundleId);
  const subscriptionId = await findSubscriptionInternalId(
    headers,
    appId,
    productId,
  );

  const rows: IStoreTerritoryPrice[] = [];
  let url: string | undefined = `${ASC_BASE_URL}/subscriptions/${subscriptionId}/prices`;
  let params: Record<string, any> | undefined = {
    include: 'subscriptionPricePoint,territory',
    limit: 200,
  };

  while (url) {
    const resp = await axios.get(url, { headers, params });
    rows.push(...mapAppleSubscriptionPricesPage(resp.data));
    url = resp.data?.links?.next;
    params = undefined; // `links.next` already carries its own query string
  }

  return rows;
}
