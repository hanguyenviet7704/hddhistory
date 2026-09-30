import { Column, Entity } from 'typeorm';

import { AbstractEntity } from '@base/database/mysql/abstract.entity';

import { PaymentPlatform } from '../../enum/payment.enum';

/**
 * Per-territory store price for one SKU, synced from Apple/Google (Part 2 of
 * plans/260727-voucher-paywall-config-affiliate/design.md). Populated ONLY by
 * `PriceService.sync()` from a live store response -- never hand-typed.
 *
 * READ-ONLY / staff visibility only. These rows must NEVER be sent to the app
 * as the price to display: the app reads the real localized price from
 * StoreKit/Play at purchase time, and a second source of truth here would
 * silently drift from what the user is actually charged (design.md hard
 * invariant #1 -- "the store owns price").
 */
@Entity({ name: 'iap_product_prices' })
export class ProductPrice extends AbstractEntity {
  @Column({
    name: 'product_id',
    type: 'varchar',
    length: 255,
    comment:
      'iap_products.productId (the SKU) -- not a foreign key, prices can ' +
      'be synced before/after the catalog row exists',
  })
  productId: string;

  @Column({ type: 'enum', enum: PaymentPlatform })
  platform: PaymentPlatform;

  @Column({
    type: 'varchar',
    length: 8,
    comment:
      'Territory code exactly as returned by the source store -- ISO ' +
      '3166-1 alpha-3 for Apple (e.g. "AUS"), alpha-2 region code for ' +
      'Google (e.g. "AU"). Never normalized across stores; do not compare ' +
      'Apple and Google rows by this column alone.',
  })
  territory: string;

  @Column({ type: 'varchar', length: 3, comment: 'ISO-4217 currency code' })
  currency: string;

  @Column({
    name: 'customer_price',
    type: 'double',
    comment:
      'READ-ONLY / staff visibility only -- never send to the app as the ' +
      'displayed price, see class-level comment',
  })
  customerPrice: number;

  @Column({
    type: 'enum',
    enum: PaymentPlatform,
    comment:
      'Which store this row was synced from. Redundant with `platform` ' +
      'today (one store == one platform) but kept as its own column in ' +
      'case a platform is ever priced from more than one source.',
  })
  source: PaymentPlatform;

  @Column({ name: 'synced_at', type: 'timestamp' })
  syncedAt: Date;

  UniqueConstraints() {
    return [['productId', 'platform', 'territory']];
  }
}
