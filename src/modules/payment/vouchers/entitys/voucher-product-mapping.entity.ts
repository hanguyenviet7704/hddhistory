import { Column, Entity, Index } from 'typeorm';

import { AbstractEntity } from '@base/database/mysql/abstract.entity';

import { PaymentPlatform } from '../../enum/payment.enum';

@Entity({ name: 'iap_voucher_product_mappings' })
@Index(['voucherId'])
@Index(['voucherId', 'platform', 'baseProductId'], { unique: true })
export class VoucherProductMapping extends AbstractEntity {
  @Column({ name: 'voucher_id', type: 'uuid' })
  voucherId: string;

  @Column({ type: 'enum', enum: PaymentPlatform })
  platform: PaymentPlatform;

  @Column({
    name: 'base_product_id',
    type: 'varchar',
    length: 255,
    comment: 'SKU shown normally',
  })
  baseProductId: string;

  @Column({
    name: 'target_product_id',
    type: 'varchar',
    length: 255,
    comment: 'Discounted SKU to show instead',
  })
  targetProductId: string;
}
