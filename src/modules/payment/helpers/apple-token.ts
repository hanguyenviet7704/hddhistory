import * as fs from 'fs';

import * as jwt from 'jsonwebtoken';

import { Configuration } from '@base/config/configuration';

export function getAppleApiToken(configService = new Configuration()) {
  const keyId = configService.getAppleKeyId;
  const issuerId = configService.getAppleIssuerId;
  const bundleId = configService.getAppleBundleId;

  if (!issuerId || !keyId || !bundleId) {
    throw new Error('Missing Apple credentials (issuerId/keyId/bundleId).');
  }

  const privateKey = fs.readFileSync(
    configService.getAppleKeyPath || 'keys/SubscriptionKey_6R3V9NBQ99.p8',
    'utf8',
  );
  const now = Math.floor(Date.now() / 1000);

  return jwt.sign(
    {
      iss: issuerId,
      iat: now,
      exp: now + 1800, // 30 minutes
      aud: 'appstoreconnect-v1',
      bid: bundleId,
    },
    privateKey,
    {
      algorithm: 'ES256',
      header: {
        alg: 'ES256',
        kid: keyId,
      },
    },
  );
}
