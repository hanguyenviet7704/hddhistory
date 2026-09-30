import { Column, Entity } from 'typeorm';

import { AbstractEntity } from '@base/database/mysql/abstract.entity';

import { PaywallConfigDto } from '../dto/paywall-config.dto';

/**
 * Append-only version history of the `paywall_config` value (previously a
 * single Firebase Remote Config parameter shared by dev AND prod -- see
 * `plans/260727-voucher-paywall-config-affiliate/design.md`). MySQL is now
 * the source of truth; each environment's API talks to its own database, so
 * the dev/prod split falls out of the deployment topology instead of Remote
 * Config conditions.
 *
 * Rows are NEVER updated in place (other than flipping `isCurrent`) --
 * `PUT /paywall-config` and `POST /paywall-config/restore/:version` both
 * insert a brand new row via `PaywallConfigRepository.publishNewVersion`.
 * This keeps the full history queryable and rollback trivial (restoring just
 * re-publishes an old row's `config` as a new, later version).
 */
@Entity({ name: 'paywall_configs' })
export class PaywallConfig extends AbstractEntity {
  @Column({ type: 'json' })
  config: PaywallConfigDto;

  @Column({ type: 'int', comment: 'Monotonically increasing, starts at 1' })
  version: number;

  @Column({ name: 'published_at', type: 'timestamp' })
  publishedAt: Date;

  @Column({
    name: 'published_by',
    type: 'varchar',
    length: 255,
    nullable: true,
    comment:
      "Admin user id/email, or the 'system:remote-config-seed' sentinel " +
      'for the version-1 row created by the first-read Remote Config seed.',
  })
  publishedBy?: string;

  @Column({
    name: 'is_current',
    type: 'boolean',
    nullable: true,
    comment:
      'true for exactly one row (the live version), NULL (never false) ' +
      'for every other row -- lets a UNIQUE KEY on this column enforce ' +
      '"at most one current row" at the database level, since MySQL unique ' +
      'indexes allow unlimited NULLs but only one of any other value.',
  })
  isCurrent?: boolean | null;
}
