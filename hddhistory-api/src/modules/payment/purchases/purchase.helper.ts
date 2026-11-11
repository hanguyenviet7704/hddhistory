import {
  BadRequestException,
  ServiceUnavailableException,
  UnauthorizedException,
} from '@nestjs/common';
import axios from 'axios';

import {
  PaymentCurrency,
  PaymentEnvironment,
  PaymentPlatform,
  ProductType,
  PurchaseStatus,
} from '../enum/payment.enum';
import { VerifyPurchaseDto } from './dto/verify-purchase.dto';
import { getAppleApiToken } from '../helpers/apple-token';
import { getGoogleAccessToken } from '../helpers/google-token';
import { decodeJwsPayload, toBool } from '../helpers/store-utils';

export interface VerifiedPurchaseResult {
  status: PurchaseStatus;
  purchaseTime: Date | null;
  expiryTime: Date | null;
  // Per-transaction unique id (Google orderId / Apple transactionId). Never
  // shared across renewals -- required by the affiliate order_id contract.
  orderId?: string;
  // Apple's originalTransactionId (subscription/renewal anchor). Undefined
  // for Google, whose anchor is derived from orderId instead.
  originalTransactionId?: string;
  anchorId?: string; // stable chain identifier best-effort
  rawPayload: string;
  storeProductId?: string;
  autoRenewing?: boolean;
  isTrial?: boolean | undefined;
  rawPrice?: number;
  currency?: PaymentCurrency | string;
  price?: string;
  failureReason?: string;
  environment?: PaymentEnvironment;
}

type DecodedTransactionInfo = {
  transactionId?: string;
  originalTransactionId?: string;
  productId?: string;
  purchaseDate?: string;
  expiresDate?: string;
  revocationDate?: string;
  revocationReason?: number | string;
  environment?: string;
  autoRenewStatus?: any;
  // Apple's JWSTransactionDecodedPayload: integer amount in milli-units
  // (e.g. 2990 === 2.99) plus an ISO-4217 currency code. There is no
  // `rawPrice` field on the Apple payload.
  price?: number | string;
  currency?: string;
  [key: string]: any;
};

function handleStoreError(
  err: any,
  badRequestMsg: string,
  unauthorizedMsg: string,
  unavailableMsg: string,
) {
  const statusRaw = err?.response?.status;
  const status =
    typeof statusRaw === 'string' ? Number(statusRaw) || statusRaw : statusRaw;
  const data = err?.response?.data;
  const message =
    typeof data === 'string'
      ? data
      : typeof data?.error?.message === 'string'
      ? data.error.message
      : typeof err?.message === 'string'
      ? err.message
      : undefined;

  if (status === 400 || status === 404) {
    throw new BadRequestException(message || badRequestMsg);
  }
  if (status === 401 || status === 403) {
    throw new UnauthorizedException(message || unauthorizedMsg);
  }
  throw new ServiceUnavailableException(message || unavailableMsg);
}

function normalizeGoogleOrderId(orderId?: string) {
  if (!orderId) return undefined;
  const parts = orderId.split('..');
  return parts[0] || orderId;
}

function mapGoogleEnvironment(data?: any): PaymentEnvironment {
  const purchaseType = data?.purchaseType;
  if (purchaseType === 0 || purchaseType === '0') {
    // Google marks license-tester purchases with purchaseType=0
    return PaymentEnvironment.SANDBOX;
  }
  return PaymentEnvironment.PRODUCTION;
}

function mapGoogleProductPurchaseState(
  purchaseState?: number,
  cancelReason?: number,
): PurchaseStatus {
  // products API: purchaseState (0 purchased, 1 canceled, 2 pending)
  if (cancelReason !== undefined && cancelReason !== null)
    return PurchaseStatus.CANCELED;
  if (purchaseState === 0) return PurchaseStatus.PAID;
  if (purchaseState === 1) return PurchaseStatus.CANCELED;
  if (purchaseState === 2) return PurchaseStatus.PENDING;
  return PurchaseStatus.PENDING;
}

export async function verifyWithStore(
  dto: VerifyPurchaseDto & { productType?: ProductType },
): Promise<VerifiedPurchaseResult> {
  switch (dto.platform) {
    case PaymentPlatform.GOOGLE:
      return isSubscriptionType(dto.productType)
        ? verifyGoogleSubscription(dto)
        : verifyGoogleProduct(dto);

    case PaymentPlatform.APPLE:
      return verifyApple(dto);

    default:
      throw new Error('Unsupported platform');
  }
}

export async function verifyGoogleProduct(
  dto: VerifyPurchaseDto,
): Promise<VerifiedPurchaseResult> {
  if (!dto.packageName) {
    throw new BadRequestException('packageName is required for Google');
  }

  const token = await getGoogleAccessToken();
  const url = `https://androidpublisher.googleapis.com/androidpublisher/v3/applications/${dto.packageName}/purchases/products/${dto.productId}/tokens/${dto.storeTransactionId}`;

  let data: any;
  try {
    const resp = await axios.get(url, {
      headers: { Authorization: `Bearer ${token}` },
    });
    data = resp.data;
  } catch (err: any) {
    handleStoreError(
      err,
      'Invalid Google product purchaseToken',
      'Google API auth failed',
      'Verify Google product failed',
    );
  }

  if (data.productId && data.productId !== dto.productId) {
    throw new BadRequestException('ProductId does not match Google payload');
  }

  const baseOrderId = normalizeGoogleOrderId(data.orderId);
  const environment = mapGoogleEnvironment(data);

  return {
    environment,
    status: mapGoogleProductPurchaseState(
      data.purchaseState,
      data.cancelReason,
    ),
    purchaseTime: data.purchaseTimeMillis
      ? new Date(Number(data.purchaseTimeMillis))
      : null,
    expiryTime: data.expiryTimeMillis
      ? new Date(Number(data.expiryTimeMillis))
      : null, // usually null for one-time products
    orderId: data.orderId,
    anchorId: baseOrderId || dto.storeTransactionId,
    rawPayload: JSON.stringify(data),
    storeProductId: data.productId,
    autoRenewing: false,
    isTrial: false,
    // price fields often not present here => keep optional
    rawPrice: data.priceAmountMicros
      ? Number(data.priceAmountMicros) / 1_000_000
      : undefined,
    currency: data.priceCurrencyCode as PaymentCurrency | undefined,
    price:
      data.priceAmountMicros && data.priceCurrencyCode
        ? `${data.priceCurrencyCode} ${
            Number(data.priceAmountMicros) / 1_000_000
          }`
        : undefined,
    failureReason:
      data.cancelReason !== undefined && data.cancelReason !== null
        ? `cancelReason=${data.cancelReason}`
        : undefined,
  };
}

function isSubscriptionType(type?: ProductType) {
  return (
    type === ProductType.SUBSCRIPTION_AUTO_RENEW ||
    type === ProductType.SUBSCRIPTION_NON_RENEW
  );
}

export async function verifyGoogleSubscription(
  dto: VerifyPurchaseDto,
): Promise<VerifiedPurchaseResult> {
  if (!dto.packageName || !dto.productId) {
    throw new BadRequestException(
      'packageName and productId(subscription SKU) are required for Google subs',
    );
  }

  // using dto.productId as subscriptionId (single-SKU principle)
  const subscriptionId = dto.productId;

  const token = await getGoogleAccessToken();
  const url = `https://androidpublisher.googleapis.com/androidpublisher/v3/applications/${dto.packageName}/purchases/subscriptions/${subscriptionId}/tokens/${dto.storeTransactionId}`;

  let data: any;
  try {
    const resp = await axios.get(url, {
      headers: { Authorization: `Bearer ${token}` },
    });
    data = resp.data;
  } catch (err: any) {
    handleStoreError(
      err,
      'Invalid Google subscription token',
      'Google API auth failed',
      'Verify Google subscription failed',
    );
  }

  if (data.productId && data.productId !== subscriptionId) {
    throw new BadRequestException(
      'SubscriptionId does not match Google payload',
    );
  }

  const expiryMs = data.expiryTimeMillis ? Number(data.expiryTimeMillis) : null;
  const purchaseTime = data.startTimeMillis
    ? new Date(Number(data.startTimeMillis))
    : null;
  const expiryTime = expiryMs ? new Date(expiryMs) : null;

  // Key rule: if still within expiry => PAID (premium valid), regardless of cancel auto-renew.
  let status: PurchaseStatus;
  if (expiryMs && expiryMs > Date.now()) {
    status = PurchaseStatus.PAID;
  } else if (data.cancelReason !== undefined && data.cancelReason !== null) {
    status = PurchaseStatus.CANCELED;
  } else if (data.paymentState === 0 || data.paymentState === 3) {
    status = PurchaseStatus.PENDING;
  } else if (data.paymentState === 1 || data.paymentState === 2) {
    status = PurchaseStatus.PAID;
  } else {
    // fallback (may not exist)
    status = mapGoogleProductPurchaseState(
      data.purchaseState,
      data.cancelReason,
    );
  }

  const environment = mapGoogleEnvironment(data);

  const baseOrderId = normalizeGoogleOrderId(data.orderId);
  // anchor best-effort:
  // - prefer base order id for stable renewal chain
  // - linkedPurchaseToken helps relate upgrade/downgrade
  // - otherwise use current purchaseToken (storeTransactionId)
  const anchorId =
    baseOrderId || data.linkedPurchaseToken || dto.storeTransactionId;

  const autoRenewing =
    data.autoRenewing !== undefined
      ? Boolean(data.autoRenewing)
      : data.userCancellationTimeMillis
      ? false
      : undefined;

  return {
    status,
    purchaseTime,
    expiryTime,
    orderId: data.orderId,
    anchorId,
    rawPayload: JSON.stringify(data),
    storeProductId: data.productId,
    autoRenewing,
    isTrial: data.paymentState === 2 ? true : undefined,
    environment,
    rawPrice: data.priceAmountMicros
      ? Number(data.priceAmountMicros) / 1_000_000
      : undefined,
    currency: data.priceCurrencyCode as PaymentCurrency | undefined,
    price:
      data.priceAmountMicros && data.priceCurrencyCode
        ? `${data.priceCurrencyCode} ${
            Number(data.priceAmountMicros) / 1_000_000
          }`
        : undefined,
    failureReason:
      data.cancelReason !== undefined && data.cancelReason !== null
        ? `cancelReason=${data.cancelReason}`
        : undefined,
  };
}

// ---- Apple helpers ----

function extractAppleSignedFields(obj: any): {
  signedTransactionInfo?: string;
  signedRenewalInfo?: string;
} {
  return {
    signedTransactionInfo:
      obj?.signedTransactionInfo ??
      obj?.data?.signedTransactionInfo ??
      obj?.data?.data?.signedTransactionInfo,
    signedRenewalInfo:
      obj?.signedRenewalInfo ??
      obj?.data?.signedRenewalInfo ??
      obj?.data?.data?.signedRenewalInfo,
  };
}

export async function verifyApple(
  dto: VerifyPurchaseDto,
): Promise<VerifiedPurchaseResult> {
  const transactionId = dto.storeTransactionId;

  const token = getAppleApiToken();

  const prodHost = 'https://api.storekit.itunes.apple.com';
  const sandboxHost = 'https://api.storekit-sandbox.itunes.apple.com';

  // Always try production first, then fallback to sandbox on expected errors
  const firstHost = prodHost;
  const secondHost = sandboxHost;

  const makeUrl = (host: string) =>
    `${host}/inApps/v1/transactions/${transactionId}`;

  let data: any;

  try {
    const resp = await axios.get(makeUrl(firstHost), {
      headers: { Authorization: `Bearer ${token}` },
    });
    data = resp.data;
  } catch (err1: any) {
    const s1 = err1?.response?.status;

    // auth sai thì khỏi thử host khác
    if (s1 === 401 || s1 === 403) {
      handleStoreError(
        err1,
        'Invalid Apple transaction id',
        'Apple API auth failed',
        'Verify Apple transaction failed',
      );
    }

    // chỉ retry khi là lỗi "có thể do sai env / id" (400/404) hoặc host đầu bị issue
    if (s1 === 400 || s1 === 404 || (s1 >= 500 && s1 <= 599)) {
      try {
        const resp2 = await axios.get(makeUrl(secondHost), {
          headers: { Authorization: `Bearer ${token}` },
        });
        data = resp2.data;
      } catch (err2: any) {
        handleStoreError(
          err2,
          'Invalid Apple transaction id',
          'Apple API auth failed',
          'Verify Apple transaction failed',
        );
      }
    } else {
      // lỗi lạ: throw theo err1
      handleStoreError(
        err1,
        'Invalid Apple transaction id',
        'Apple API auth failed',
        'Verify Apple transaction failed',
      );
    }
  }

  const { signedTransactionInfo, signedRenewalInfo } =
    extractAppleSignedFields(data);

  let tx: DecodedTransactionInfo = (data?.data ?? data) as any;
  let renewal: DecodedTransactionInfo | undefined;

  const decodedTx =
    typeof signedTransactionInfo === 'string'
      ? decodeJwsPayload<DecodedTransactionInfo>(signedTransactionInfo)
      : undefined;
  if (decodedTx) tx = decodedTx;

  const decodedRenewal =
    typeof signedRenewalInfo === 'string'
      ? decodeJwsPayload<DecodedTransactionInfo>(signedRenewalInfo)
      : undefined;
  if (decodedRenewal) renewal = decodedRenewal;

  if (tx.productId && dto.productId && tx.productId !== dto.productId) {
    throw new BadRequestException('ProductId does not match Apple payload');
  }

  const refunded =
    Boolean(tx.revocationDate) || tx.revocationReason !== undefined;

  const status = refunded
    ? PurchaseStatus.REFUNDED
    : tx.purchaseDate
    ? PurchaseStatus.PAID
    : PurchaseStatus.PENDING;

  const purchaseTime = tx.purchaseDate ? new Date(tx.purchaseDate) : null;
  const expiryTime = tx.expiresDate ? new Date(tx.expiresDate) : null;

  // `anchorId` groups renewals of the same subscription and MUST keep
  // resolving to the same value it always has (originalTransactionId first,
  // falling back the same way as before) -- only `orderId` below changes to
  // stop sharing that anchor value across every renewal.
  const originalTransactionId = tx.originalTransactionId || undefined;
  const anchorId =
    tx.originalTransactionId || tx.transactionId || transactionId;
  // Per-transaction unique id -- this is what the affiliate order_id
  // contract needs (one id per renewal, not one shared id per subscription).
  const perTransactionOrderId = tx.transactionId || transactionId;

  const autoRenewing =
    toBool(tx.autoRenewStatus) ?? toBool(renewal?.autoRenewStatus);

  // Apple's `price` is an integer in milli-units (2990 === 2.99); convert to
  // the same decimal-amount unit the rest of the pipeline (Google, products)
  // uses. Keep rawPrice/currency as a single pair sourced from the same `tx`
  // payload -- never let currency come from `tx` while the amount is left to
  // fall back to the product catalog.
  const rawPrice =
    tx.price !== undefined && tx.price !== null
      ? Number(tx.price) / 1000
      : undefined;

  const rawPayload = {
    notificationType: renewal?.notificationType,
    transactionId: tx.transactionId,
    originalTransactionId: tx.originalTransactionId,
    productId: tx.productId,
    purchaseDate: tx.purchaseDate,
    expiresDate: tx.expiresDate,
    environment: tx.environment,
    revocationReason: tx.revocationReason,
    revocationDate: tx.revocationDate,
    autoRenewStatus: renewal?.autoRenewStatus ?? tx.autoRenewStatus ?? null,
    expirationIntent: renewal?.expirationIntent ?? null,
    // Raw (un-converted, milli-units) amount, exactly as Apple sent it.
    rawPrice: tx.price ?? undefined,
    currency: tx.currency ?? undefined,
    paymentStatus: status,
    autoRenewing,
    isTrial: undefined as boolean | undefined,
  };

  return {
    status,
    purchaseTime,
    expiryTime,
    orderId: perTransactionOrderId,
    originalTransactionId,
    anchorId,
    rawPayload: JSON.stringify(rawPayload),
    storeProductId: tx.productId,
    autoRenewing,
    isTrial: undefined as boolean | undefined,
    rawPrice,
    currency: tx.currency,
    environment:
      String(tx.environment || '').toLowerCase() === 'sandbox'
        ? PaymentEnvironment.SANDBOX
        : PaymentEnvironment.PRODUCTION,
    failureReason: refunded
      ? `revocationReason=${tx.revocationReason ?? 'revoked'}`
      : undefined,
  };
}
