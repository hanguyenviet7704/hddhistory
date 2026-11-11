import { timingSafeEqual } from 'crypto';

import {
  CanActivate,
  ExecutionContext,
  ForbiddenException,
  Injectable,
} from '@nestjs/common';

import { Configuration } from '@base/config/configuration';

/**
 * Protects `POST /purchase/affiliateOrder`: the route is `@Public()` (no
 * JWT), so this is the only gate. Rejects with 403 unless the request body's
 * `key_project` matches AFFILIATE_ORDERS_SECRET_TOKEN, using a timing-safe
 * comparison so response time can't be used to brute-force the secret
 * character by character.
 */
@Injectable()
export class AffiliateKeyGuard implements CanActivate {
  constructor(private readonly configService: Configuration) {}

  canActivate(context: ExecutionContext): boolean {
    const request = context.switchToHttp().getRequest();
    const provided = request?.body?.key_project;
    const expected = this.configService.getAffiliateOrdersSecretToken;

    if (!expected || !this.isMatch(provided, expected)) {
      throw new ForbiddenException('Invalid key_project');
    }

    return true;
  }

  private isMatch(provided: unknown, expected: string): boolean {
    if (typeof provided !== 'string' || !provided) return false;

    const providedBuffer = Buffer.from(provided);
    const expectedBuffer = Buffer.from(expected);
    // timingSafeEqual throws on length mismatch -- compare lengths first.
    // This length check itself is not constant-time, but leaking the
    // secret's length is an accepted trade-off (same as most timing-safe
    // token comparisons); it never leaks anything about its content.
    if (providedBuffer.length !== expectedBuffer.length) return false;

    return timingSafeEqual(providedBuffer, expectedBuffer);
  }
}
