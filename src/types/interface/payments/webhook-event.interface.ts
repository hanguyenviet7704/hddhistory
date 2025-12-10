import { PaymentPlatform } from "../../enum/payment.enum";
import { BaseQuery } from "../common.interface";

export interface IWebhookEvent {
  id: string;
  platform: PaymentPlatform;
  eventType: string;
  rawBody: string;
  processed: boolean;
  processedAt?: Date;
  error?: string;
}

export class WebhookEventListQuery extends BaseQuery {
  constructor(init?: Partial<WebhookEventListQuery>) {
    super(init);
    Object.assign(this, init);
  }

  override toQueryParams(): string {
    const params = new URLSearchParams(super.toQueryParams());

    return params.toString();
  }
}
