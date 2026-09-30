import {
  PaymentEnvironment,
  PaymentPlatform,
  PurchaseEventType,
  PurchaseHistorySource,
  PurchaseStatus,
} from '../../enum/payment.enum';

export interface IPurchase {
  id: string;
  userId: string;
  userName?: string;
  userEmail?: string;
  platform: PaymentPlatform;
  environment?: PaymentEnvironment;
  eventType: PurchaseEventType;
  storeTransactionId: string;
  productId: string;
  orderId?: string;
  // Apple's originalTransactionId (subscription/renewal anchor). Google
  // purchases leave this undefined. See entities/purchase.entity.ts.
  originalTransactionId?: string;
  // ISO-4217 code as snapshotted from the store; not restricted to
  // PaymentCurrency (see entities/purchase.entity.ts).
  currency?: string;
  rawPrice?: number;
  price?: string;
  status: PurchaseStatus;
  isRenewal: boolean;
  purchaseTime?: Date;
  expiryTime?: Date;
  rawPayload?: string;
  failureReason?: string;
  statusHistory?: Array<{
    at: string;
    status: PurchaseStatus;
    source: PurchaseHistorySource;
    purchaseTime?: string | null;
    expiryTime?: string | null;
  }>;
  idempotencyKey?: string;
  isManual?: boolean;
  // Voucher redemption snapshot -- see entities/purchase.entity.ts.
  voucherCode?: string;
  voucherDiscountPercent?: number;
  // Purchasing user profile snapshot, captured at verify() time.
  country?: string;
  language?: string;
}
