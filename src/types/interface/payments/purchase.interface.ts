import {
  PaymentCurrency,
  PaymentPlatform,
  PurchaseStatus,
} from "../../enum/payment.enum";
import { BaseQuery } from "../common.interface";

export interface IPurchase {
  id: string;
  userId: string;
  platform: PaymentPlatform;
  storeTransactionId: string;
  productId: string;
  orderId?: string;
  currency?: PaymentCurrency;
  rawPrice?: number;
  price?: string;
  status: PurchaseStatus;
  purchaseTime?: Date;
  expiryTime?: Date;
  rawPayload?: string;
  failureReason?: string;
  idempotencyKey?: string;
}

export class PurchaseListQuery extends BaseQuery {
  platform?: PaymentPlatform;
  status?: PurchaseStatus;

  constructor(init?: Partial<PurchaseListQuery>) {
    super(init);
    Object.assign(this, init);
  }

  override toQueryParams(): string {
    const params = new URLSearchParams(super.toQueryParams());
    if (this.platform) params.set("platform", this.platform);
    if (this.status) params.set("status", this.status);

    return params.toString();
  }
}
