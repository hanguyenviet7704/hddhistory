import { ForbiddenException } from '@nestjs/common';

import { AffiliateKeyGuard } from './affiliate-key.guard';

const SECRET = 'affiliate-super-secret-value';

function makeGuard(secret?: string): AffiliateKeyGuard {
  const configService: any = { getAffiliateOrdersSecretToken: secret };
  return new AffiliateKeyGuard(configService);
}

function makeContext(body: any): any {
  return {
    switchToHttp: () => ({
      getRequest: () => ({ body }),
    }),
  };
}

describe('AffiliateKeyGuard', () => {
  it('allows the request when key_project matches the configured secret exactly', () => {
    const guard = makeGuard(SECRET);

    expect(guard.canActivate(makeContext({ key_project: SECRET }))).toBe(true);
  });

  it('rejects with 403 when key_project does not match', () => {
    const guard = makeGuard(SECRET);

    expect(() =>
      guard.canActivate(makeContext({ key_project: 'wrong-secret' })),
    ).toThrow(ForbiddenException);
  });

  it('rejects with 403 when key_project has a different length than the secret', () => {
    const guard = makeGuard(SECRET);

    expect(() =>
      guard.canActivate(makeContext({ key_project: 'short' })),
    ).toThrow(ForbiddenException);
  });

  it('rejects with 403 when key_project is missing from the body', () => {
    const guard = makeGuard(SECRET);

    expect(() => guard.canActivate(makeContext({}))).toThrow(
      ForbiddenException,
    );
  });

  it('rejects with 403 when key_project is not a string', () => {
    const guard = makeGuard(SECRET);

    expect(() =>
      guard.canActivate(makeContext({ key_project: 12345 })),
    ).toThrow(ForbiddenException);
  });

  it('fails closed (403) when no secret is configured on the server', () => {
    const guard = makeGuard(undefined);

    expect(() =>
      guard.canActivate(makeContext({ key_project: SECRET })),
    ).toThrow(ForbiddenException);
  });
});
