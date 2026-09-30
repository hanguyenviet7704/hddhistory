import axios from 'axios';

import { getGoogleAccessToken } from '../../helpers/google-token';
import { IStoreTerritoryPrice } from '../interfaces/product-price.interface';

/**
 * Pure mapping of one `monetization.subscriptions.get` response
 * (`GET /androidpublisher/v3/applications/{package}/subscriptions/{id}`) to
 * territory price rows, reading `basePlans[].regionalConfigs[].price`
 * (`units` + `nanos` + `currencyCode`).
 *
 * A SKU can have more than one base plan (e.g. monthly + yearly grouped
 * under one subscription id); every regional config from every base plan is
 * folded into one row set. If two base plans price the same region
 * differently, the later one encountered wins -- acceptable for a
 * display-only sync (see ProductPrice entity comment), but noted here since
 * it is a real, if unlikely, source of ambiguity.
 */
export function mapGoogleSubscriptionPricesResponse(response: {
  basePlans?: any[];
}): IStoreTerritoryPrice[] {
  const rows: IStoreTerritoryPrice[] = [];
  for (const basePlan of response?.basePlans ?? []) {
    for (const regionalConfig of basePlan?.regionalConfigs ?? []) {
      const price = regionalConfig?.price;
      const regionCode = regionalConfig?.regionCode;
      if (!price || !regionCode || !price.currencyCode) continue;

      const units = Number(price.units ?? 0);
      const nanos = Number(price.nanos ?? 0);

      rows.push({
        territory: regionCode,
        currency: price.currencyCode,
        customerPrice: units + nanos / 1_000_000_000,
      });
    }
  }
  return rows;
}

/**
 * Reuses the existing service-account JWT client (`androidpublisher` scope,
 * already granted for purchase verification). NOTE: reading *monetization*
 * data is a Play Console permission distinct from purchase verification and
 * could not be verified from this machine -- see design.md Part 2 risk note.
 * A 401/403 here almost certainly means that permission hasn't been granted
 * yet, not a code bug.
 */
export async function fetchGoogleTerritoryPrices(
  packageName: string,
  productId: string,
): Promise<IStoreTerritoryPrice[]> {
  const token = await getGoogleAccessToken();
  const url = `https://androidpublisher.googleapis.com/androidpublisher/v3/applications/${packageName}/subscriptions/${productId}`;

  const resp = await axios.get(url, {
    headers: { Authorization: `Bearer ${token}` },
  });

  return mapGoogleSubscriptionPricesResponse(resp.data);
}
