import { Column, Entity, Index } from 'typeorm';

import { AbstractEntity } from '@base/database/mysql/abstract.entity';

import {
  PaymentEnvironment,
  PaymentPlatform,
  SubscriptionStatus,
} from '../../enum/payment.enum';

@Entity({ name: 'iap_subscriptions' })
@Index(['userId']) // Lấy subscription theo user
@Index(['anchorId', 'productId', 'platform', 'environment'], { unique: true }) // 1 anchorId có thể có nhiều productId
export class Subscription extends AbstractEntity {
  @Column({ name: 'user_id', type: 'varchar', length: 64 })
  userId: string;

  @Column({ name: 'user_name', type: 'varchar', length: 255, nullable: true })
  userName?: string;

  @Column({ name: 'user_email', type: 'varchar', length: 255, nullable: true })
  userEmail?: string;

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

  @Column({
    name: 'product_id',
    type: 'varchar',
    length: 255,
    comment: 'SKU của sản phẩm (premium_monthly, yearly...)',
  })
  productId: string;

  @Column({
    name: 'anchor_id',
    type: 'varchar',
    length: 255,
    comment:
      'Apple: originalTransactionId; Google: orderId base hoặc purchaseToken gốc',
  })
  anchorId: string;

  @Column({
    type: 'enum',
    enum: SubscriptionStatus,
    comment: 'cập nhật theo store/webhook',
  })
  status: SubscriptionStatus;

  @Column({
    name: 'current_period_start',
    type: 'datetime',
    nullable: true,
    comment: 'Thời gian bắt đầu chu kỳ hiện tại (từ App Store / Play Store)',
  })
  currentPeriodStart: Date;

  @Column({
    name: 'current_period_end',
    type: 'datetime',
    nullable: true,
    comment:
      'Thời gian kết thúc chu kỳ hiện tại (expiryTimeMillis / expiresDate)',
  })
  currentPeriodEnd: Date;

  @Column({
    name: 'auto_renewing',
    type: 'boolean',
    default: true,
    comment: 'User có bật auto-renew không (store gửi)',
  })
  autoRenewing: boolean;

  @Column({
    name: 'is_trial',
    type: 'boolean',
    default: false,
    comment: 'Có phải đang ở giai đoạn trial không',
  })
  isTrial: boolean;

  @Column({
    name: 'last_verified_at',
    type: 'datetime',
    comment: 'Lần gần nhất đồng bộ từ verify hoặc webhook',
  })
  lastVerifiedAt: Date;

  @Column({
    name: 'last_event_at',
    type: 'datetime',
    comment:
      'Timestamp của sự kiện thực tế từ store (renew, cancel...). Quan trọng hơn lastVerifiedAt',
  })
  lastEventAt: Date;

  @Column({
    name: 'is_manual',
    type: 'boolean',
    default: false,
    comment: 'Subscription được tạo thủ công (không qua store/webhook)',
  })
  isManual: boolean;
}
