import {
  PaymentCurrency,
  PaymentPlatform,
  PurchaseEventType,
  PurchaseStatus,
} from "../../enum/payment.enum";
import { BaseQuery } from "../common.interface";

export interface IPurchase {
  id: string;
  userId: string;
  userName?: string;
  userEmail?: string;
  platform: PaymentPlatform;
  eventType: PurchaseEventType;
  storeTransactionId: string;
  productId: string;
  orderId?: string;
  currency?: PaymentCurrency;
  rawPrice?: number;
  price?: string;
  status: PurchaseStatus;
  isRenewal: boolean;
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

export class GetRevenueListQuery extends BaseQuery {
  currency!: PaymentCurrency;
  from?: string;
  to?: string;
  platform?: PaymentPlatform;
  status?: PurchaseStatus;
  productId?: string;

  constructor(init?: Partial<GetRevenueListQuery>) {
    super(init);
    Object.assign(this, init);
  }

  override toQueryParams(): string {
    const params = new URLSearchParams(super.toQueryParams());
    params.set("currency", this.currency);
    if (this.platform) params.set("platform", this.platform);
    if (this.status) params.set("status", this.status);
    if (this.from) params.set("from", this.from);
    if (this.to) params.set("to", this.to);
    if (this.productId) params.set("productId", this.productId);

    return params.toString();
  }
}

export interface RevenueStatisticsResponse {
  currency: string;
  totalRevenue: number;
  refundedRevenue: number;
  totalPurchases: number;
}
