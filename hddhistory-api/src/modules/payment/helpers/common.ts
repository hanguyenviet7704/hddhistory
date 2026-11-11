import { Configuration } from '@base/config/configuration';

import {
  PaymentEnvironment,
  PurchaseStatus,
  SubscriptionStatus,
} from '../enum/payment.enum';

export function mapPurchaseStatusToSubscription(
  status: PurchaseStatus,
): SubscriptionStatus {
  switch (status) {
    case PurchaseStatus.PAID:
      return SubscriptionStatus.ACTIVE;
    case PurchaseStatus.PENDING:
      return SubscriptionStatus.ON_HOLD;
    case PurchaseStatus.CANCELED:
    case PurchaseStatus.REFUNDED:
      return SubscriptionStatus.CANCELED;
    case PurchaseStatus.FAILED:
    default:
      return SubscriptionStatus.EXPIRED;
  }
}

export function resolveSubscriptionStatus(
  status: PurchaseStatus,
  expiryTime?: Date | null,
  now: Date = new Date(),
): SubscriptionStatus {
  if (expiryTime && expiryTime.getTime() <= now.getTime()) {
    return SubscriptionStatus.EXPIRED;
  }

  return mapPurchaseStatusToSubscription(status);
}

export function statusRank(status: PurchaseStatus) {
  switch (status) {
    case PurchaseStatus.PENDING:
      return 0;
    case PurchaseStatus.FAILED:
      return 1;
    case PurchaseStatus.PAID:
      return 2;
    case PurchaseStatus.CANCELED:
      return 3;
    case PurchaseStatus.REFUNDED:
      return 4;
    default:
      return 0;
  }
}

export function preferHigherStatus(
  current: PurchaseStatus,
  incoming: PurchaseStatus,
): PurchaseStatus {
  return statusRank(incoming) >= statusRank(current) ? incoming : current;
}

export function getEnvironment(
  config: Configuration,
): PaymentEnvironment | undefined {
  const env = (config.getEnvironment || '').toLowerCase();
  if (env === 'production') return PaymentEnvironment.PRODUCTION;
  if (env === 'development') return PaymentEnvironment.SANDBOX;
  return undefined;
}
