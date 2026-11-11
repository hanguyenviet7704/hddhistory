import { Column, Entity } from 'typeorm';

import { AbstractEntity } from '@base/database/mysql/abstract.entity';

import {
  PaymentCurrency,
  PaymentPlatform,
  ProductType,
} from '../../enum/payment.enum';

@Entity({ name: 'iap_products' })
export class Product extends AbstractEntity {
  @Column({ type: 'enum', enum: PaymentPlatform })
  platform: PaymentPlatform;

  @Column({
    name: 'product_id',
    type: 'varchar',
    length: 255,
    comment: 'The product identifier from the platform',
  })
  productId: string;

  @Column({ type: 'enum', enum: ProductType })
  type: ProductType;

  @Column({ type: 'varchar', length: 255 })
  title: string;

  @Column({ type: 'text', nullable: true })
  description?: string;

  @Column({
    type: 'enum',
    enum: PaymentCurrency,
    default: PaymentCurrency.USD,
  })
  currency: PaymentCurrency;

  @Column({
    name: 'raw_price',
    type: 'double',
    nullable: true,
  })
  rawPrice?: number;

  @Column({ type: 'varchar', length: 64, nullable: true })
  price?: string;

  @Column({
    name: 'sale_price',
    type: 'double',
    nullable: true,
  })
  salePrice?: number;

  @Column({ name: 'is_active', default: true })
  isActive: boolean;

  @Column({ name: 'best_deal', type: 'boolean', default: false })
  bestDeal: boolean;

  @Column({
    name: 'discount_percent',
    type: 'tinyint',
    unsigned: true,
    nullable: true,
    comment: '0-100 — shown as badge on paywall (e.g. 50 → "-50%")',
  })
  salePercent?: number;

  @Column({
    name: 'compare_at_product_id',
    type: 'varchar',
    length: 255,
    nullable: true,
    comment:
      'Another SKU on the same platform whose real store price the paywall ' +
      'strikes through above this one. A reference, never an amount: the app ' +
      'asks the store for this SKU so the struck price is localized per ' +
      'storefront and can never drift from what Apple/Google charge. NULL = ' +
      'no struck-through price.',
  })
  compareAtProductId?: string;

  UniqueConstraints() {
    return [['platform', 'productId']];
  }
}
