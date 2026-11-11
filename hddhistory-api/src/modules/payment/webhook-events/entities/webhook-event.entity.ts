import { Column, Entity, Index } from 'typeorm';

import { AbstractEntity } from '@base/database/mysql/abstract.entity';

import { PaymentEnvironment, PaymentPlatform } from '../../enum/payment.enum';

@Entity({ name: 'iap_webhook_events' })
export class WebhookEvent extends AbstractEntity {
  @Column({ type: 'enum', enum: PaymentPlatform })
  platform: PaymentPlatform;

  @Column({
    name: 'environment',
    type: 'enum',
    enum: PaymentEnvironment,
    nullable: true,
    comment: 'production / sandbox',
  })
  environment?: PaymentEnvironment;

  @Column({ name: 'event_type', type: 'varchar', length: 255, nullable: true })
  eventType: string;

  @Column({ name: 'raw_body', type: 'text', nullable: true })
  rawBody: string;

  @Column({ type: 'boolean', default: false })
  processed: boolean;

  @Column({ name: 'processed_at', type: 'datetime', nullable: true })
  processedAt?: Date;

  @Column({ type: 'text', nullable: true })
  error?: string;

  @Index()
  @Column({ name: 'purchase_id', type: 'varchar', length: 64, nullable: true })
  purchaseId?: string;
}
