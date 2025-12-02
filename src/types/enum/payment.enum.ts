export enum PaymentPlatform {
  GOOGLE = "google",
  APPLE = "apple",
}

export enum PaymentCurrency {
  USD = "USD",
  VND = "VND",
}

export enum ProductType {
  SUBSCRIPTION = "subscription",
  IN_APP = "in_app",
  NON_RENEWABLE = "non_renewable",
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
