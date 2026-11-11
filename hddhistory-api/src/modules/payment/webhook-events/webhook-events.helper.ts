import {
  createPublicKey,
  verify as cryptoVerify,
  X509Certificate,
} from 'crypto';

import { BadRequestException, UnauthorizedException } from '@nestjs/common';
import { OAuth2Client } from 'google-auth-library';

import {
  PaymentEnvironment,
  PaymentPlatform,
  ProductType,
  PurchaseStatus,
} from '../enum/payment.enum';
import {
  decodeB64Json,
  decodeJwsPayload,
  toBool,
} from '../helpers/store-utils';
import { ProductRepository } from '../products/repositories/product.repository';
import { verifyWithStore } from '../purchases/purchase.helper';
import { PurchaseRepository } from '../purchases/repositories/purchase.repository';

export { buildPriceSnapshot } from '../helpers/store-utils';

export function normalizeEnvironment(
  value?: any,
): PaymentEnvironment | undefined {
  if (typeof value !== 'string') return undefined;
  const env = value.toLowerCase();
  if (env === PaymentEnvironment.SANDBOX) return PaymentEnvironment.SANDBOX;
  if (env === PaymentEnvironment.PRODUCTION)
    return PaymentEnvironment.PRODUCTION;
  return undefined;
}

export function unwrapPubSubBody(dto: any) {
  const normalizePlatform = (raw?: any): PaymentPlatform | undefined => {
    const value =
      typeof raw === 'string' ? raw.toLowerCase() : (raw as PaymentPlatform);
    if (value === PaymentPlatform.GOOGLE) return PaymentPlatform.GOOGLE;
    if (value === PaymentPlatform.APPLE) return PaymentPlatform.APPLE;
    return undefined;
  };

  const rawBody =
    typeof dto?.rawBody === 'string'
      ? dto.rawBody
      : (() => {
          try {
            return JSON.stringify(dto);
          } catch {
            return '';
          }
        })();

  const pubSubMessage = dto?.message;
  if (pubSubMessage && typeof pubSubMessage.data === 'string') {
    let decodedText = '';
    try {
      decodedText = Buffer.from(pubSubMessage.data, 'base64').toString('utf8');
    } catch (err) {
      throw new BadRequestException(
        'Invalid Pub/Sub data encoding',
        err instanceof Error ? err.message : undefined,
      );
    }

    let decoded: any;
    try {
      decoded = JSON.parse(decodedText);
    } catch {
      throw new BadRequestException('Pub/Sub data is not valid JSON');
    }

    const isGoogleRtdn =
      !!decoded.subscriptionNotification || !!decoded.packageName;
    const platform =
      normalizePlatform(
        decoded.platform ??
          pubSubMessage.attributes?.platform ??
          (isGoogleRtdn ? PaymentPlatform.GOOGLE : undefined),
      ) ?? normalizePlatform(dto?.platform);

    const notificationType = decoded.subscriptionNotification?.notificationType;
    const eventType =
      decoded.eventType ||
      pubSubMessage.attributes?.eventType ||
      pubSubMessage.attributes?.type ||
      pubSubMessage.attributes?.event_type ||
      (notificationType !== undefined
        ? `google.subscription_notification.${notificationType}`
        : undefined);

    const payload =
      decoded.payload ??
      decoded.subscriptionNotification ??
      decoded.data ??
      decoded;

    return {
      ...decoded,
      platform,
      eventType,
      rawBody: decodedText,
      payload,
    };
  }

  // Apple ASSN v2 (signedPayload in body)
  if (typeof dto?.signedPayload === 'string') {
    const applePayload = decodeJwsPayload(dto.signedPayload);
    const notificationType =
      applePayload?.notificationType || applePayload?.subtype;

    return {
      ...dto,
      platform: PaymentPlatform.APPLE,
      eventType: dto.eventType || notificationType,
      payload: dto.payload || applePayload || {},
      rawBody,
    };
  }

  return {
    ...dto,
    platform: normalizePlatform(dto?.platform),
    rawBody,
    payload: dto.payload ?? dto,
  };
}

export async function parseGooglePayload(
  dto: any,
  deps: {
    productRepo: ProductRepository;
    purchaseRepo?: PurchaseRepository;
  },
) {
  const body = dto.payload ?? {};
  const subNoti =
    dto.subscriptionNotification ?? body.subscriptionNotification ?? null;
  const purchaseToken =
    body.purchaseToken ??
    body.storeTransactionId ??
    subNoti?.purchaseToken ??
    dto.purchaseToken;
  const subscriptionId =
    body.subscriptionId ?? subNoti?.subscriptionId ?? body.productId;
  const packageName = body.packageName ?? dto.packageName;

  const isSubscriptionNotification = !!subNoti;
  if (!purchaseToken || !subscriptionId || !isSubscriptionNotification) {
    return undefined;
  }
  if (!packageName) {
    throw new BadRequestException('packageName is required for Google');
  }

  const existingPurchase = deps.purchaseRepo
    ? await deps.purchaseRepo.findByTransaction(purchaseToken)
    : undefined;

  const product =
    (await deps.productRepo.findOne({
      productId: subscriptionId,
      platform: PaymentPlatform.GOOGLE,
    })) || undefined;
  const verified = await verifyWithStore({
    platform: PaymentPlatform.GOOGLE,
    productId: subscriptionId,
    packageName,
    storeTransactionId: purchaseToken,
    productType: product?.type ?? ProductType.SUBSCRIPTION_AUTO_RENEW,
  });

  const productId =
    verified.storeProductId || existingPurchase?.productId || subscriptionId;

  const environment =
    normalizeEnvironment(verified.environment) ??
    normalizeEnvironment(existingPurchase?.environment) ??
    normalizeEnvironment(body.environment);
  const anchorId =
    verified.anchorId ??
    existingPurchase?.orderId ??
    existingPurchase?.storeTransactionId;

  return {
    environment,
    ...(existingPurchase?.userId ? { userId: existingPurchase.userId } : {}),
    ...(existingPurchase?.userName
      ? { userName: existingPurchase.userName }
      : {}),
    ...(existingPurchase?.userEmail
      ? { userEmail: existingPurchase.userEmail }
      : {}),
    productId,
    storeTransactionId: purchaseToken,
    orderId: verified.orderId ?? existingPurchase?.orderId,
    // Google has no separate "original" id — its orderId is already the stable
    // one. Declared so every branch of this union carries the same shape.
    originalTransactionId: undefined as string | undefined,
    anchorId,
    purchaseTime: verified.purchaseTime,
    expiryTime: verified.expiryTime,
    rawPayload: verified.rawPayload,
    status: verified.status,
    autoRenewing: verified.autoRenewing,
    isTrial: verified.isTrial,
    failureReason: verified.failureReason,
    rawPrice: verified.rawPrice,
    currency: verified.currency,
    price: verified.price,
  };
}

export function parseApplePayload(dto: any) {
  const payload = dto.payload ?? {};
  const data = payload.data ?? {};
  const txInfo = decodeJwsPayload(data.signedTransactionInfo);
  const renewalInfo = decodeJwsPayload(data.signedRenewalInfo);
  const notificationType =
    payload.notificationType || renewalInfo?.notificationType;

  const productId =
    txInfo?.productId || renewalInfo?.productId || payload.productId;
  const storeTransactionId =
    txInfo?.transactionId || payload.storeTransactionId;
  // `orderId` must identify ONE order: Apple sends a fresh `transactionId` per
  // renewal while `originalTransactionId` stays constant for the whole
  // subscription, so anchoring both on the original made every renewal share
  // an id (which collapses rows in the affiliate order feed). Mirrors the same
  // fix in purchases/purchase.helper.ts.
  //
  // `anchorId` deliberately keeps the ORIGINAL formula — subscription
  // anchoring depends on one stable id across renewals. It must NOT be derived
  // from `orderId` any more, or this change would silently re-anchor
  // subscriptions.
  const originalTransactionId = txInfo?.originalTransactionId;
  const orderId = txInfo?.transactionId || payload.orderId;
  const anchorId =
    originalTransactionId || payload.orderId || storeTransactionId;

  if (!productId || !storeTransactionId) return undefined;

  const purchaseTime = parseDateMs(
    txInfo?.purchaseDate ?? txInfo?.purchaseDateMs,
  );
  const expiryTime = parseDateMs(
    txInfo?.expiresDate ?? txInfo?.expiresDateMs ?? renewalInfo?.expiresDateMs,
  );
  const autoRenewing =
    renewalInfo?.autoRenewStatus !== undefined
      ? toBool(renewalInfo.autoRenewStatus)
      : undefined;
  const eventState = inferEventState(notificationType);
  const status =
    eventState.status === PurchaseStatus.PENDING && purchaseTime
      ? PurchaseStatus.PAID
      : eventState.status;
  const autoRenewingFinal =
    autoRenewing !== undefined ? autoRenewing : eventState.autoRenewing;

  const rawPayload = {
    notificationType,
    transactionId: txInfo?.transactionId,
    originalTransactionId: txInfo?.originalTransactionId,
    productId: txInfo?.productId,
    purchaseDate: txInfo?.purchaseDate ?? txInfo?.purchaseDateMs ?? null,
    expiresDate: txInfo?.expiresDate ?? txInfo?.expiresDateMs ?? null,
    environment: txInfo?.environment,
    revocationReason: txInfo?.revocationReason,
    revocationDate: txInfo?.revocationDate,
    autoRenewStatus:
      renewalInfo?.autoRenewStatus ?? txInfo?.autoRenewStatus ?? null,
    expirationIntent: renewalInfo?.expirationIntent ?? null,
    rawPrice: payload.rawPrice ?? null,
    price: payload.price ?? null,
    currency: payload.currency ?? txInfo?.currency ?? null,
    paymentStatus: status,
    autoRenewing: autoRenewingFinal,
    isTrial: payload.isTrial ?? null,
  };

  return {
    environment:
      String(txInfo?.environment || '').toLowerCase() === 'sandbox'
        ? PaymentEnvironment.SANDBOX
        : PaymentEnvironment.PRODUCTION,
    userId: payload.userId,
    productId,
    storeTransactionId,
    orderId,
    originalTransactionId,
    anchorId,
    purchaseTime,
    expiryTime,
    rawPayload: JSON.stringify(rawPayload),
    status,
    autoRenewing: autoRenewingFinal,
    isTrial: undefined as boolean | undefined,
    failureReason: renewalInfo?.expirationIntent,
    rawPrice: undefined as number | undefined,
    currency: undefined as string | undefined,
    price: undefined as string | undefined,
  };
}

export async function verifyGoogleOidcToken(
  authorization?: string,
  audience?: string,
  expectedEmail?: string,
) {
  const payload = await verifyOidcToken(authorization, audience);
  const iss = payload?.iss;
  if (iss !== 'https://accounts.google.com' && iss !== 'accounts.google.com') {
    throw new UnauthorizedException('Invalid token issuer');
  }

  if (expectedEmail) {
    const emailOrSub = payload.email || payload.sub;
    if (emailOrSub !== expectedEmail) {
      throw new UnauthorizedException('Invalid token subject');
    }
  }
}

export async function verifyAppleSignedPayload(
  signedPayload: string,
  opts?: { bundleId?: string },
) {
  const parts = signedPayload.split('.');
  if (parts.length !== 3) {
    throw new UnauthorizedException('Invalid Apple signedPayload format');
  }
  const [headerB64, payloadB64, signatureB64] = parts;

  const header = decodeB64Json<any>(headerB64);
  const pem = extractAppleCert(header);
  const cert = new X509Certificate(pem);
  const now = Date.now();
  if (cert.validFrom && new Date(cert.validFrom).getTime() > now) {
    throw new UnauthorizedException('Apple certificate not yet valid');
  }
  if (cert.validTo && new Date(cert.validTo).getTime() < now) {
    throw new UnauthorizedException('Apple certificate expired');
  }
  const publicKey = createPublicKey(cert.toString());

  const signingInput = Buffer.from(`${headerB64}.${payloadB64}`);
  const signature = Buffer.from(signatureB64, 'base64url');

  const ok = cryptoVerify(
    'sha256',
    signingInput,
    { key: publicKey, dsaEncoding: 'ieee-p1363' },
    signature,
  );

  if (!ok) {
    throw new UnauthorizedException('Invalid Apple signedPayload signature');
  }

  const payload = decodeB64Json<any>(payloadB64);
  if (payload?.iss && payload.iss !== 'appstoreconnect-v1') {
    throw new UnauthorizedException('Invalid Apple issuer');
  }
  const expectedBundle = opts?.bundleId;
  if (
    payload?.bundleId &&
    expectedBundle &&
    payload.bundleId !== expectedBundle
  ) {
    throw new UnauthorizedException('Apple bundleId mismatch');
  }
  // environment is provided by Apple inside the signed payload; downstream code
  // should use that value instead of server environment variables.
  const nowSec = Math.floor(Date.now() / 1000);
  if (payload?.exp && payload.exp < nowSec) {
    throw new UnauthorizedException('Apple signedPayload expired');
  }
  return payload;
}

export function inferEventState(eventType: string): {
  status: PurchaseStatus;
  autoRenewing?: boolean;
} {
  const eventTypeLower = (eventType || '').toLowerCase();

  const googlePrefix = 'google.subscription_notification.';
  if (eventTypeLower.startsWith(googlePrefix)) {
    const typeNum = Number(eventTypeLower.slice(googlePrefix.length));
    switch (typeNum) {
      case 1: // RECOVERED
      case 2: // RENEWED
      case 4: // PURCHASED
      case 7: // RESTARTED
      case 8: // PRICE_CHANGE_CONFIRMED
        return { status: PurchaseStatus.PAID, autoRenewing: true };
      case 3: // CANCELED (auto-renew off, entitlement remains until expiry)
        return { status: PurchaseStatus.PAID, autoRenewing: false };
      case 13: // EXPIRED
        return { status: PurchaseStatus.CANCELED, autoRenewing: false };
      case 5: // ON_HOLD
      case 6: // IN_GRACE_PERIOD
      case 9: // DEFERRED
        return { status: PurchaseStatus.PENDING, autoRenewing: true };
      case 10: // PAUSED
      case 11: // PAUSE_SCHEDULE_CHANGED
        return { status: PurchaseStatus.PENDING, autoRenewing: false };
      case 12: // REVOKED
        return { status: PurchaseStatus.REFUNDED, autoRenewing: false };
      default:
        break;
    }
  }

  // 1) Hard revoke/refund
  if (
    eventTypeLower.includes('refund') ||
    eventTypeLower.includes('chargeback') ||
    eventTypeLower.includes('revoke')
  ) {
    return { status: PurchaseStatus.REFUNDED, autoRenewing: false };
  }

  // 2) Expired event from store
  if (eventTypeLower.includes('expire')) {
    return { status: PurchaseStatus.CANCELED, autoRenewing: false };
  }

  // 3) Chỉ tắt gia hạn tự động nhưng gói vẫn còn đến hết kỳ.
  const autoRenewOffKeywords = [
    'auto_renew_off',
    'auto-renew-off',
    'disable_auto_renew',
    'turn_off_auto_renew',
    'cancel_renewal',
    'did_change_renewal_status',
  ];
  const isAutoRenewOff = autoRenewOffKeywords.some(k =>
    eventTypeLower.includes(k),
  );
  if (isAutoRenewOff) {
    return { status: PurchaseStatus.PAID, autoRenewing: false };
  }

  // 4) Explicit cancellation (tránh match nhầm noise)
  const cancelKeywords = ['cancel', 'canceled', 'cancellation'];
  const cancelNoise = ['survey', 'date_changed', 'price_change'];
  const isCancel =
    cancelKeywords.some(k => eventTypeLower.includes(k)) &&
    !cancelNoise.some(k => eventTypeLower.includes(k));
  if (isCancel) {
    return { status: PurchaseStatus.PAID, autoRenewing: false };
  }

  // 5) Billing failures/grace (chờ retry)
  if (
    eventTypeLower.includes('fail') ||
    eventTypeLower.includes('billing_retry') ||
    eventTypeLower.includes('grace')
  ) {
    return { status: PurchaseStatus.PENDING };
  }

  // 6) Purchase/renewal events
  if (eventTypeLower.includes('renew') || eventTypeLower.includes('purchase')) {
    return { status: PurchaseStatus.PAID };
  }

  return { status: PurchaseStatus.PENDING };
}

function parseDateMs(value: any): Date | null {
  if (value === undefined || value === null) return null;
  const num =
    typeof value === 'number'
      ? value
      : typeof value === 'string'
      ? Number(value)
      : undefined;
  if (num === undefined || Number.isNaN(num)) return null;
  return new Date(num);
}

function extractAppleCert(header: any) {
  const x5c: string[] | undefined = header?.x5c;
  if (!Array.isArray(x5c) || x5c.length === 0) {
    throw new UnauthorizedException('Apple JWS missing certificate chain');
  }
  const leaf = x5c[0];
  const pem = `-----BEGIN CERTIFICATE-----\n${leaf}\n-----END CERTIFICATE-----`;
  return pem;
}

function extractBearerToken(authorization?: string) {
  if (!authorization) return '';
  const [scheme, ...rest] = authorization.trim().split(' ');
  if (!scheme || scheme.toLowerCase() !== 'bearer') return '';
  return rest.join(' ').trim();
}

async function verifyOidcToken(authorization?: string, audience?: string) {
  const token = extractBearerToken(authorization);
  if (!token) {
    throw new UnauthorizedException('Missing Authorization bearer token');
  }

  const client = new OAuth2Client();
  const ticket = await client.verifyIdToken({
    idToken: token,
    audience: audience || undefined,
  });

  const payload = ticket.getPayload();
  if (!payload) {
    throw new UnauthorizedException('Invalid OIDC token payload');
  }

  return payload;
}
