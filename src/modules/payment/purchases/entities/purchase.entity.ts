import { Column, Entity, Index } from 'typeorm';

import { AbstractEntity } from '@base/database/mysql/abstract.entity';

import {
  PaymentEnvironment,
  PaymentPlatform,
  PurchaseEventType,
  PurchaseHistorySource,
  PurchaseStatus,
} from '../../enum/payment.enum';

@Entity({ name: 'iap_purchases' })
@Index(['userId'])
@Index(['productId'])
@Index(['voucherCode'])
export class Purchase extends AbstractEntity {
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
    comment: 'production / sandbox / test',
  })
  environment?: PaymentEnvironment;

  @Column({
    name: 'store_transaction_id',
    type: 'text',
    comment:
      'purchaseToken (Google) hoặc transactionId/receipt (Apple). TEXT để chứa PKCS7 receipt dài',
  })
  storeTransactionId: string;

  @Column({ name: 'product_id', type: 'varchar', length: 255 })
  productId: string;

  @Column({
    name: 'order_id',
    type: 'varchar',
    length: 255,
    nullable: true,
    comment:
      'Per-transaction unique order id (Google orderId / Apple transactionId). ' +
      'See originalTransactionId for the Apple renewal-anchor id.',
  })
  orderId?: string;

  @Column({
    name: 'original_transaction_id',
    type: 'varchar',
    length: 255,
    nullable: true,
    comment:
      "Apple's originalTransactionId (subscription/renewal anchor). Google " +
      'purchases leave this null -- their anchor is derived from orderId.',
  })
  originalTransactionId?: string;

  @Column({
    type: 'varchar',
    length: 3,
    nullable: true,
    comment:
      'ISO-4217 currency code snapshotted from the store at purchase time ' +
      '(NOT restricted to PaymentCurrency -- Google Play alone is live in ' +
      '174 countries/currencies)',
  })
  currency?: string;

  @Column({ name: 'raw_price', type: 'double', nullable: true })
  rawPrice?: number;

  @Column({ type: 'varchar', length: 64, nullable: true })
  price?: string;

  @Column({
    type: 'enum',
    enum: PurchaseStatus,
    default: PurchaseStatus.PENDING,
  })
  status: PurchaseStatus;

  @Column({
    name: 'event_type',
    type: 'enum',
    enum: PurchaseEventType,
    default: PurchaseEventType.INITIAL,
    comment: 'initial/renewal/cancel/refund (logical event type)',
  })
  eventType: PurchaseEventType;

  @Column({
    name: 'is_renewal',
    type: 'boolean',
    default: false,
    comment: 'True nếu là bản ghi gia hạn (renew) cùng anchor/order trước đó',
  })
  isRenewal: boolean;

  @Column({ name: 'purchase_time', type: 'datetime', nullable: true })
  purchaseTime?: Date;

  @Column({ name: 'expiry_time', type: 'datetime', nullable: true })
  expiryTime?: Date;

  @Column({
    name: 'raw_payload',
    type: 'text',
    nullable: true,
  })
  rawPayload?: string;

  @Column({
    name: 'failure_reason',
    type: 'text',
    nullable: true,
    comment: 'Lý do fail/cancel (nếu có)',
  })
  failureReason?: string;

  @Column({
    name: 'processed_at',
    type: 'datetime',
    nullable: true,
    comment: 'Đánh dấu đã xử lý receipt/webhook',
  })
  processedAt?: Date;

  @Column({ name: 'status_history', type: 'json', nullable: true })
  statusHistory?: Array<{
    at: string;
    status: PurchaseStatus;
    source: PurchaseHistorySource;
    purchaseTime?: string | null;
    expiryTime?: string | null;
  }>;

  @Column({
    name: 'is_manual',
    type: 'boolean',
    default: false,
    comment: 'Purchase được tạo thủ công (không qua store/webhook)',
  })
  isManual: boolean;

  // idempotencyKey phải unique theo user hoặc platform
  @Index(['userId', 'idempotencyKey'], { unique: true })
  @Column({
    name: 'idempotency_key',
    type: 'varchar',
    length: 255,
    nullable: true,
    comment: 'Prevent duplicate verify',
  })
  idempotencyKey?: string;

  @Column({
    name: 'voucher_code',
    type: 'varchar',
    length: 64,
    nullable: true,
    comment:
      'Voucher code applied at verify() time (re-validated server-side). ' +
      'Null when no voucher was used or the code no longer validated -- a ' +
      'stale code never blocks the purchase.',
  })
  voucherCode?: string;

  @Column({
    name: 'voucher_discount_percent',
    type: 'tinyint',
    unsigned: true,
    nullable: true,
    comment:
      'Snapshot of iap_vouchers.discount_percent at redemption time -- ' +
      'display/reporting only, paired with voucherCode above.',
  })
  voucherDiscountPercent?: number;

  @Column({
    name: 'entered_code',
    type: 'varchar',
    length: 64,
    nullable: true,
    comment:
      'Promo/affiliate code as the buyer typed it, kept even when it matches ' +
      'no voucher -- attribution for the affiliate feed, never a discount. ' +
      'Separate from voucherCode, which means "validated AND redeemed" and ' +
      'is counted against Voucher.perUserLimit.',
  })
  enteredCode?: string;

  @Column({
    name: 'logic_sale_id',
    type: 'varchar',
    length: 64,
    nullable: true,
    comment:
      'Paywall LogicSale campaign the app reported at verify time. ' +
      'Attribution for the campaign statistics only - never a discount. ' +
      'Written once at INSERT, never backfilled onto renewals.',
  })
  logicSaleId?: string;

  @Column({
    name: 'paywall_experiment_key',
    type: 'varchar',
    length: 64,
    nullable: true,
    comment:
      'Paywall body A/B run the app reported at verify time. Attribution ' +
      'for the experiment readout only - never a discount. Written once at ' +
      'INSERT, never backfilled onto renewals.',
  })
  paywallExperimentKey?: string;

  @Column({
    name: 'paywall_body_variant',
    type: 'varchar',
    length: 16,
    nullable: true,
    comment: 'Arm of that run: benefits | comparison',
  })
  paywallBodyVariant?: string;

  @Column({
    type: 'varchar',
    length: 64,
    nullable: true,
    comment: "Snapshot of the purchasing user's Mongo profile country at verify() time",
  })
  country?: string;

  @Column({
    type: 'varchar',
    length: 32,
    nullable: true,
    comment: "Snapshot of the purchasing user's Mongo profile language at verify() time",
  })
  language?: string;
}
