import { MigrationInterface, QueryRunner } from 'typeorm';

/**
 * Moves `paywall_config`'s source of truth from a single Firebase Remote
 * Config parameter (shared by dev AND prod -- `plans/260727-voucher-paywall-
 * config-affiliate/design.md` Part 3) into MySQL, so each environment's own
 * database is the split instead of a Remote Config condition.
 *
 * Append-only: `paywall_configs` keeps every published version (see
 * `PaywallConfig` entity / `PaywallConfigRepository.publishNewVersion`) so
 * history and rollback are native, which Remote Config gave for free and this
 * migration otherwise would have taken away.
 *
 * Written defensively like AddIapProductPrices1785114000000:
 * `CREATE TABLE IF NOT EXISTS` so re-running against an already-migrated
 * database is a no-op rather than an error -- a failing migration would stop
 * the app from booting (`migrationsRun: true` in mysql.module.ts).
 */
export class AddPaywallConfigsTable1785232800000 implements MigrationInterface {
  name = 'AddPaywallConfigsTable1785232800000';

  public async up(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(`
      CREATE TABLE IF NOT EXISTS \`paywall_configs\` (
        \`id\`           VARCHAR(36)  NOT NULL,
        \`createdBy\`    VARCHAR(36)  NULL,
        \`updatedBy\`    VARCHAR(36)  NULL,
        \`createdAt\`    TIMESTAMP(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
        \`updatedAt\`    TIMESTAMP(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6)
                           ON UPDATE CURRENT_TIMESTAMP(6),
        \`config\`       JSON         NOT NULL
                           COMMENT 'Full paywall_config JSON blob, same shape the Flutter client parses today',
        \`version\`      INT          NOT NULL
                           COMMENT 'Monotonically increasing, starts at 1',
        \`published_at\` TIMESTAMP(6) NOT NULL,
        \`published_by\` VARCHAR(255) NULL
                           COMMENT 'Admin user id/email, or the system:remote-config-seed sentinel for the version-1 seed row',
        \`is_current\`   TINYINT(1)   NULL
                           COMMENT 'true for exactly one row (the live version); NULL (never false) for every other row so the UNIQUE KEY below can enforce at most one current row at the DB level',
        PRIMARY KEY (\`id\`),
        UNIQUE KEY \`UQ_paywall_configs_version\` (\`version\`),
        UNIQUE KEY \`UQ_paywall_configs_is_current\` (\`is_current\`)
      ) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4 COLLATE = utf8mb4_unicode_ci
    `);
  }

  public async down(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(`DROP TABLE IF EXISTS \`paywall_configs\``);
  }
}
