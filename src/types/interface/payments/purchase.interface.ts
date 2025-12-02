import { PaymentPlatform, PurchaseStatus } from "../../enum/payment.enum";

export interface IPurchase {
  id: string;
  userId: string;
  platform: PaymentPlatform;
  storeTransactionId: string;
  productId: string;
  orderId?: string;
  status: PurchaseStatus;
  purchaseTime?: Date;
  expiryTime?: Date;
  rawPayload?: string;
  idempotencyKey?: string;
}
