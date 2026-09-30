import { PaymentPlatform } from '../../enum/payment.enum';

export interface IWebhookEvent {
  id: string;
  platform: PaymentPlatform;
  eventType: string;
  rawBody: string;
  processed: boolean;
  processedAt?: Date;
  error?: string;
}
