/**
 * Fixed configuration for the affiliate voucher service (voucher.eup.ai).
 *
 * Hardcoded rather than env-driven on purpose: the host is one
 * company-internal service shared by every environment, and PRODUCT_ID
 * identifies the HDDhistory *app*, not a deployment -- there is no dev/stg/prod
 * variant to swap in. The trade-off is that rotating either value is a code
 * change plus a deploy.
 */

export const AFFILIATE_VOUCHER_BASE_URL = 'https://voucher.eup.ai';

/**
 * HDDhistory's id INSIDE voucher.eup.ai, issued by the affiliate team.
 *
 * Do not confuse it with the two neighbouring values it looks nothing like in
 * purpose but easily gets mixed up with:
 *  - a HDDhistory `iap_products.id` / `product_id` -- unrelated, ours, per package;
 *  - `AFFILIATE_ORDERS_SECRET_TOKEN` (`key_project`) -- the INBOUND secret
 *    guarding our own POST /purchase/affiliateOrder.
 * Sending either of those here returns 404 from every endpoint.
 */
export const AFFILIATE_VOUCHER_PRODUCT_ID =
  'b2f4d9a7-1c8e-4f63-9a15-e7c3b6d82f40';

/**
 * Ceiling for both calls. This is a product decision, not a network one: the
 * lookup sits on a path the user is actively staring at, and the service has
 * been observed hanging past 12s on a code that did not exist. Exceeding it
 * degrades to `unavailable`, which still sells at the normal price.
 */
export const AFFILIATE_VOUCHER_TIMEOUT_MS = 3000;
