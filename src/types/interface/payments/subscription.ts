import { PaymentPlatform, SubscriptionStatus } from "../../enum/payment.enum";

export interface ISubscription {
  id: string;
  userId: string;
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
}
