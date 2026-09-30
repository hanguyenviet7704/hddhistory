import { Column, Entity } from 'typeorm';

import { AbstractEntity } from '@base/database/mysql/abstract.entity';

@Entity({ name: 'iap_vouchers' })
export class Voucher extends AbstractEntity {
  @Column({
    type: 'varchar',
    length: 64,
    unique: true,
    comment: 'Always stored trimmed + uppercased',
  })
  code: string;

  @Column({
    type: 'varchar',
    length: 255,
    nullable: true,
    comment: 'Affiliate owner, for reporting only',
  })
  owner?: string;

  @Column({
    name: 'discount_percent',
    type: 'tinyint',
    unsigned: true,
    nullable: true,
    comment:
      'DISPLAY/REPORTING ONLY. The real discount is whatever the target SKU ' +
      "costs in the user's territory; never compute a charge from this field.",
  })
  discountPercent?: number;

  @Column({ name: 'valid_from', type: 'datetime', nullable: true })
  validFrom?: Date;

  @Column({ name: 'valid_to', type: 'datetime', nullable: true })
  validTo?: Date;

  @Column({
    name: 'max_uses',
    type: 'int',
    nullable: true,
    comment: 'Null = unlimited',
  })
  maxUses?: number;

  @Column({ name: 'used_count', type: 'int', default: 0 })
  usedCount: number;

  @Column({
    name: 'per_user_limit',
    type: 'int',
    nullable: true,
    comment: 'Null = unlimited',
  })
  perUserLimit?: number;

  @Column({
    type: 'simple-array',
    nullable: true,
    comment: 'ISO country allow-list. Null/empty = all countries',
  })
  countries?: string[];

  @Column({ name: 'is_active', type: 'boolean', default: true })
  isActive: boolean;
}
