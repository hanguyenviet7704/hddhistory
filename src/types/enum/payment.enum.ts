export enum PaymentPlatform {
  GOOGLE = "google",
  APPLE = "apple",
}

export enum PaymentCurrency {
  USD = "USD",
  VND = "VND",
}

export enum ProductType {
  SUBSCRIPTION_NON_RENEW = "subscription_non_renew",
  SUBSCRIPTION_AUTO_RENEW = "subscription_auto_renew",
  NON_CONSUMABLE = "non_consumable",
  CONSUMABLE = "consumable",
}

export enum PurchaseStatus {
  PENDING = "pending",
  PAID = "paid",
  FAILED = "failed",
  CANCELED = "canceled",
  REFUNDED = "refunded",
}

export enum SubscriptionStatus {
  ACTIVE = "active",
  EXPIRED = "expired",
  GRACE = "grace", //  gian gia hạn trễ, vẫn còn premium
  ON_HOLD = "on_hold", // payment fail quá nhiều lần, permission bị tạm khóa
  CANCELED = "canceled", // user đã tắt auto-renew, nhưng vẫn còn dùng đến cuối kỳ
}

export enum PurchaseEventType {
  INITIAL = "initial",
  RENEWAL = "renewal",
  CANCEL = "cancel",
  REFUND = "refund",
}
