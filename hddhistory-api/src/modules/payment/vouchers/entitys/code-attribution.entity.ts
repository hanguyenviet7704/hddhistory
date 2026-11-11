import { Column, Entity, Index } from 'typeorm';

import { AbstractEntity } from '@base/database/mysql/abstract.entity';

/**
 * A promo/affiliate code as a user APPLIED it, recorded the moment they apply
 * rather than when a purchase completes.
 *
 * Until this existed the code lived only in the app's memory between the
 * paywall and `verify()`, so it was lost whenever that stretch broke: the app
 * killed on the store sheet, a failed verify, or Ask-to-Buy completing hours
 * later with the app long gone. A purchase that arrives without a code falls
 * back to the newest unconsumed row here for that user.
 *
 * Every applied code is recorded, including ones the affiliate service does
 * not recognise — the point is attribution, not entitlement, and a typo is
 * worth seeing in the report.
 */
@Entity({ name: 'iap_code_attributions' })
@Index(['userId', 'consumedAt'])
export class CodeAttribution extends AbstractEntity {
  @Column({ name: 'user_id', type: 'varchar', length: 64 })
  userId: string;

  @Column({
    type: 'varchar',
    length: 64,
    comment: 'As typed, trimmed + uppercased',
  })
  code: string;

  @Column({
    name: 'consumed_at',
    type: 'timestamp',
    nullable: true,
    comment:
      'Set when a purchase took this code. Single-use on purpose: a code ' +
      'applied once must not keep crediting every later purchase.',
  })
  consumedAt?: Date;

  @Column({
    name: 'consumed_by_purchase_id',
    type: 'varchar',
    length: 64,
    nullable: true,
    comment: 'iap_purchases.id that took it — the audit trail for the partner',
  })
  consumedByPurchaseId?: string;
}
