import { Product } from '../products/entitys/product.entity';

/**
 * Decode a base64url JSON string.
 */
export function decodeB64Json<T = any>(b64: string): T {
  const json = Buffer.from(b64, 'base64url').toString('utf8');
  return JSON.parse(json) as T;
}

/**
 * Decode the payload part of a JWS into JSON (best effort).
 */
export function decodeJwsPayload<T = any>(jws?: string): T | undefined {
  if (!jws || typeof jws !== 'string') return undefined;
  const parts = jws.split('.');
  if (parts.length < 2) return undefined;
  try {
    return decodeB64Json<T>(parts[1]);
  } catch {
    return undefined;
  }
}

/**
 * Convert assorted truthy/falsey tokens from store payloads to boolean.
 */
export function toBool(value: any): boolean | undefined {
  if (value === true || value === false) return value;
  if (value === 1 || value === '1') return true;
  if (value === 0 || value === '0') return false;
  if (typeof value === 'string') {
    const lower = value.toLowerCase();
    if (lower === 'true') return true;
    if (lower === 'false') return false;
  }
  return undefined;
}

/**
 * Snapshot price at event time; allows overriding with store payload fields.
 *
 * `rawPrice`, `currency`, and `price` are treated as ONE atomic triple that
 * must always come from the same source: either the store payload (when it
 * supplied a real amount) or the product catalog row. They must never be
 * mixed across sources -- e.g. a store-reported `currency` combined with the
 * product's local `rawPrice` -- because that produces a snapshot that looks
 * valid (`{ currency: 'VND', rawPrice: 2.99 }`) but is wrong by orders of
 * magnitude (a $2.99 USD product actually charged ~75,000 VND).
 */
export function buildPriceSnapshot(
  product: Product,
  override?: { rawPrice?: number; currency?: string; price?: string },
) {
  const hasOverrideAmount =
    override?.rawPrice !== undefined && override?.rawPrice !== null;

  const rawPrice = hasOverrideAmount
    ? override.rawPrice
    : product.salePrice ?? product.rawPrice ?? undefined;
  // The mirror of the rule above: a store amount keeps the store's currency or
  // NO currency at all. Borrowing `product.currency` here is what wrote
  // `{ rawPrice: 9.99, currency: 'VND' }` -- a USD charge labelled in dong,
  // which reads as 9.99 VND (~0.0004 USD) to anyone summing the feed. An
  // unknown currency is recoverable from the receipt later; a confidently
  // wrong one is not.
  const currency = hasOverrideAmount
    ? override?.currency
    : product.currency;
  // Only trust the store's own display string when it rode in together with
  // the store's own amount; otherwise build the label from whichever pair we
  // actually picked (never pair the store's string with the product's pair).
  const priceLabel = hasOverrideAmount ? override?.price : product.price;

  return {
    currency,
    rawPrice,
    price:
      priceLabel ??
      (rawPrice !== undefined && rawPrice !== null
        ? currency
          ? `${currency} ${rawPrice}`
          : String(rawPrice)
        : undefined),
  };
}
