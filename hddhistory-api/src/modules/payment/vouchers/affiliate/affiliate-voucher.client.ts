import { Injectable, Logger } from '@nestjs/common';

import {
  AFFILIATE_VOUCHER_BASE_URL,
  AFFILIATE_VOUCHER_PRODUCT_ID,
  AFFILIATE_VOUCHER_TIMEOUT_MS,
} from './affiliate-voucher.constant';

/** Why a lookup did not produce a usable answer. */
export type AffiliateVoucherFailure =
  /** Their 404. Ambiguous by their design -- see `mapStatus`. */
  | 'not_found'
  /** Their 422: the body failed validation on their side. */
  | 'invalid_input'
  /** Timeout, network error, 5xx, or an unparseable 200. */
  | 'unavailable';

export interface AffiliateVoucherPackage {
  packageKey: string;
  discountPercent: number;
}

/**
 * Exactly one of the two is set. Modelled as optional fields rather than a
 * discriminated union on purpose: this project builds with
 * `strictNullChecks: false`, under which TypeScript will not narrow a union by
 * a boolean discriminant, so the tidier `{ ok: true } | { ok: false }` shape
 * fails to compile at every call site.
 */
export interface AffiliateVoucherGetResult {
  packages?: AffiliateVoucherPackage[];
  failure?: AffiliateVoucherFailure;
}

interface AffiliateVoucherPostResult {
  body?: unknown;
  failure?: AffiliateVoucherFailure;
}

interface AffiliateVoucherIdentity {
  userId?: string;
  email?: string;
}

/**
 * Thin client over the affiliate team's voucher service, which is the source
 * of truth for every promo code HDDhistory honours.
 *
 * Two rules shape this class:
 *
 * 1. **It never throws.** A promo-code lookup failing must not take down the
 *    paywall -- the user should still be able to buy at the normal price. So
 *    every outcome, including a wedged socket, comes back as a value.
 *
 * 2. **It speaks their wire format, not ours.** snake_case bodies, their
 *    status-code vocabulary, their `package_key` namespace. Translation into
 *    HDDhistory concepts happens in VoucherService, so their contract changing has
 *    one blast radius.
 */
@Injectable()
export class AffiliateVoucherClient {
  private readonly logger = new Logger(AffiliateVoucherClient.name);

  async get(
    code: string,
    identity: AffiliateVoucherIdentity = {},
  ): Promise<AffiliateVoucherGetResult> {
    const response = await this.post('/voucher/get', {
      code,
      ...this.identityBody(identity),
    });

    if (response.failure) return { failure: response.failure };

    const packages = this.parsePackages(response.body);
    if (!packages) {
      this.logger.error(
        `Unparseable /voucher/get body for code ${code}: ${JSON.stringify(
          response.body,
        )}`,
      );
      return { failure: 'unavailable' };
    }

    return { packages };
  }

  /**
   * Reports a redemption. Fire-and-forget by contract: the caller has already
   * taken the user's money, so nothing here may fail the purchase. Attribution
   * is not lost if this call dies -- `iap_purchases.voucher_code` is persisted
   * and POST /purchase/affiliateOrder is the reconciliation path.
   *
   * `discountPercent` is the EFFECTIVE percentage, which is not always the
   * code's own: when a code is worse than the sale already running, the spec
   * asks for the default sale percentage instead so the affiliate still gets
   * credit for referring the user.
   */
  async use(args: {
    code: string;
    packageKey: string;
    identity?: AffiliateVoucherIdentity;
  }): Promise<boolean> {
    const response = await this.post('/voucher/use', {
      code: args.code,
      package_key: args.packageKey,
      ...this.identityBody(args.identity ?? {}),
    });

    if (!response.failure) return true;

    this.logger.warn(
      `/voucher/use failed (${response.failure}) for code ${args.code}, ` +
        `package ${args.packageKey}. Attribution still recoverable via the ` +
        `affiliate orders export.`,
    );
    return false;
  }

  private identityBody(identity: AffiliateVoucherIdentity) {
    // Both are optional on their side. Omit rather than send empty strings --
    // an empty user_id reads as a real value and would group every anonymous
    // redemption under one identity in their reporting.
    return {
      ...(identity.userId ? { user_id: identity.userId } : {}),
      ...(identity.email ? { email: identity.email } : {}),
    };
  }

  private async post(
    path: string,
    body: Record<string, unknown>,
  ): Promise<AffiliateVoucherPostResult> {
    const controller = new AbortController();
    const timeoutId = setTimeout(
      () => controller.abort(),
      AFFILIATE_VOUCHER_TIMEOUT_MS,
    );

    let response: Response;
    try {
      response = await fetch(`${AFFILIATE_VOUCHER_BASE_URL}${path}`, {
        method: 'POST',
        headers: {
          accept: 'application/json',
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({
          product_id: AFFILIATE_VOUCHER_PRODUCT_ID,
          ...body,
        }),
        signal: controller.signal,
      });
    } catch (error: any) {
      const reason =
        error?.name === 'AbortError'
          ? `timed out after ${AFFILIATE_VOUCHER_TIMEOUT_MS}ms`
          : (error?.message ?? 'network error');
      this.logger.warn(`POST ${path} ${reason}`);
      return { failure: 'unavailable' };
    } finally {
      clearTimeout(timeoutId);
    }

    if (!response.ok) {
      return { failure: await this.mapStatus(path, response) };
    }

    try {
      return { body: await response.json() };
    } catch {
      return { failure: 'unavailable' };
    }
  }

  private async mapStatus(
    path: string,
    response: Response,
  ): Promise<AffiliateVoucherFailure> {
    const detail = await response.text().catch(() => '');

    if (response.status === 404) {
      // Their 404 body is the same generic "endpoint does not exist" whether
      // the CODE is unknown or the PRODUCT_ID is -- verified by probing both.
      // So a misconfigured product id is indistinguishable from every user
      // mistyping a code. The tell is the ratio: an occasional 404 is normal
      // traffic, a 404 on every single request means the product id is wrong.
      this.logger.debug(
        `POST ${path} 404 -- unknown code, or (if EVERY request 404s) ` +
          `AFFILIATE_VOUCHER_PRODUCT_ID is not registered on their side`,
      );
      return 'not_found';
    }

    if (response.status === 422) {
      this.logger.warn(`POST ${path} 422 rejected our body: ${detail}`);
      return 'invalid_input';
    }

    this.logger.warn(`POST ${path} returned ${response.status}: ${detail}`);
    return 'unavailable';
  }

  /**
   * `{"vouchers":[{"package_key":"pre1months","discount":10}]}` -> our shape.
   * Returns null when the payload is not that shape at all (their contract
   * moved), and skips individual malformed entries so one bad row cannot cost
   * the user the rest of a working code.
   */
  private parsePackages(body: unknown): AffiliateVoucherPackage[] | null {
    const vouchers = (body as { vouchers?: unknown })?.vouchers;
    if (!Array.isArray(vouchers)) return null;

    const packages: AffiliateVoucherPackage[] = [];
    for (const entry of vouchers) {
      const packageKey = (entry as { package_key?: unknown })?.package_key;
      const discount = (entry as { discount?: unknown })?.discount;
      if (typeof packageKey !== 'string' || !packageKey) continue;
      if (typeof discount !== 'number' || !Number.isFinite(discount)) continue;
      packages.push({
        packageKey,
        discountPercent: Math.trunc(discount),
      });
    }
    return packages;
  }
}
