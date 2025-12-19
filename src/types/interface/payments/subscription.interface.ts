import {
  PaymentCurrency,
  PaymentEnvironment,
  PaymentPlatform,
  SubscriptionStatus,
} from "../../enum/payment.enum";
import { BaseQuery } from "../common.interface";

export interface ISubscription {
  id: string;
  userId: string;
  userName?: string;
  userEmail?: string;
  platform: PaymentPlatform;
  productId: string;
  anchorId: string;
  status: SubscriptionStatus;
  currentPeriodStart?: Date;
  currentPeriodEnd?: Date;
  autoRenewing: boolean;
  isTrial: boolean;
  lastVerifiedAt?: Date;
  lastEventAt?: Date;
  isManual?: boolean;
}

export interface ManualSubscriptionPayload {
  confirmPassword: string;
  userId: string;
  userName?: string;
  userEmail?: string;
  productId: string;
  rawPrice: number;
  currency: PaymentCurrency;
  purchaseTime?: string;
  expiryTime?: string;
  environment: PaymentEnvironment;
}

export interface DeleteSubscriptionPayload {
  confirmPassword: string;
}

export class SubscriptionListQuery extends BaseQuery {
  environment!: PaymentEnvironment;
  userId?: string = "";
  platform?: PaymentPlatform;
  status?: SubscriptionStatus;

  constructor(init?: Partial<SubscriptionListQuery>) {
    super(init);
    Object.assign(this, init);
  }

  override toQueryParams(): string {
    const params = new URLSearchParams(super.toQueryParams());
    params.set("environment", this.environment);
    if (this.userId) params.set("userId", this.userId);
    if (this.platform) params.set("platform", this.platform);
    if (this.status) params.set("status", this.status);

    return params.toString();
  }
}
