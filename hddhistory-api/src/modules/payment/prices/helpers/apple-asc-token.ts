import * as fs from 'fs';

import * as jwt from 'jsonwebtoken';

import { Configuration } from '@base/config/configuration';

/**
 * ES256 JWT for the App Store Connect API. Distinct from
 * `payment/helpers/apple-token.ts` (which signs App Store Server API tokens
 * for purchase verification/webhooks) -- ASC requires its own key pair,
 * provisioned separately in App Store Connect under Users and Access > Keys,
 * even though the signing shape is identical.
 *
 * Reads the raw key content from `APPLE_ASC_PRIVATE_KEY` (not a file path,
 * unlike `apple-token.ts`'s `APPLE_KEY_PATH`) since the API server has no
 * checked-in `.p8` file for these credentials -- they live in the Flutter
 * repo (`hddhistory-flutter/.info/app/app.json`) and must be copied into env vars
 * here before the sync can run.
 */
export function getAppleAscApiToken(configService = new Configuration()): string {
  const keyId = configService.getAppleAscKeyId;
  const issuerId = configService.getAppleAscIssuerId;
  // Two ways to supply the key, because this repo already mounts the App Store
  // *Server* key as a file (see apple-token.ts / APPLE_KEY_PATH, with `keys/`
  // excluded from the image): APPLE_ASC_PRIVATE_KEY holds the raw PEM, or
  // APPLE_ASC_KEY_PATH points at a mounted .p8 so k8s config can follow the
  // convention already in place. Raw content wins when both are set.
  const keyPath = configService.getAppleAscKeyPath;
  const privateKeyRaw =
    configService.getAppleAscPrivateKey ||
    (keyPath && fs.existsSync(keyPath)
      ? fs.readFileSync(keyPath, 'utf8')
      : undefined);

  if (!keyId || !issuerId || !privateKeyRaw) {
    throw new Error(
      'Missing App Store Connect credentials ' +
        '(APPLE_ASC_KEY_ID / APPLE_ASC_ISSUER_ID / APPLE_ASC_PRIVATE_KEY or APPLE_ASC_KEY_PATH).',
    );
  }

  // PEM keys stored in a single-line env var commonly escape real newlines
  // as the two characters "\n" -- restore them before handing to
  // `jsonwebtoken`, which requires an actual multi-line PEM string.
  const privateKey = privateKeyRaw.includes('\\n')
    ? privateKeyRaw.replace(/\\n/g, '\n')
    : privateKeyRaw;

  const now = Math.floor(Date.now() / 1000);

  return jwt.sign(
    {
      iss: issuerId,
      iat: now,
      exp: now + 1100, // App Store Connect API tokens are capped at 20 minutes
      aud: 'appstoreconnect-v1',
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
