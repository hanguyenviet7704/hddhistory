import { MigrationInterface, QueryRunner } from 'typeorm';

/**
 * Voucher tables + the new iap_purchases columns for promo attribution and the
 * affiliate order feed.
 *
 * Written defensively: some of this DDL may already have been applied by hand
 * (the repo had no migration system before this, so tables were provisioned
 * manually). Every step checks information_schema first, so running it against
 * a partially-migrated database is a no-op rather than an error — and a failing
 * migration would stop the app from booting.
 */
export class AddVoucherAndPurchaseColumns1785110400000
  implements MigrationInterface
{
  name = 'AddVoucherAndPurchaseColumns1785110400000';

  public async up(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(`
      CREATE TABLE IF NOT EXISTS \`iap_vouchers\` (
        \`id\`               VARCHAR(36)      NOT NULL,
        \`createdBy\`        VARCHAR(36)      NULL,
        \`updatedBy\`        VARCHAR(36)      NULL,
        \`createdAt\`        TIMESTAMP(6)     NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
        \`updatedAt\`        TIMESTAMP(6)     NOT NULL DEFAULT CURRENT_TIMESTAMP(6)
                               ON UPDATE CURRENT_TIMESTAMP(6),
        \`code\`             VARCHAR(64)      NOT NULL,
        \`owner\`            VARCHAR(255)     NULL,
        \`discount_percent\` TINYINT UNSIGNED NULL
                               COMMENT 'Display/reporting only; the real discount is the target SKU price',
        \`valid_from\`       DATETIME         NULL,
        \`valid_to\`         DATETIME         NULL,
        \`max_uses\`         INT              NULL,
        \`used_count\`       INT              NOT NULL DEFAULT 0,
        \`per_user_limit\`   INT              NULL,
        \`countries\`        TEXT             NULL,
        \`is_active\`        TINYINT(1)       NOT NULL DEFAULT 1,
        PRIMARY KEY (\`id\`),
        UNIQUE KEY \`UQ_iap_vouchers_code\` (\`code\`)
      ) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4 COLLATE = utf8mb4_unicode_ci
    `);

    await queryRunner.query(`
      CREATE TABLE IF NOT EXISTS \`iap_voucher_product_mappings\` (
        \`id\`                VARCHAR(36)  NOT NULL,
        \`createdBy\`         VARCHAR(36)  NULL,
        \`updatedBy\`         VARCHAR(36)  NULL,
        \`createdAt\`         TIMESTAMP(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
        \`updatedAt\`         TIMESTAMP(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6)
                                ON UPDATE CURRENT_TIMESTAMP(6),
        \`voucher_id\`        VARCHAR(36)  NOT NULL,
        \`platform\`          ENUM('google','apple') NOT NULL,
        \`base_product_id\`   VARCHAR(255) NOT NULL,
        \`target_product_id\` VARCHAR(255) NOT NULL,
        PRIMARY KEY (\`id\`),
        KEY \`IDX_iap_voucher_mappings_voucher\` (\`voucher_id\`),
        UNIQUE KEY \`UQ_iap_voucher_mappings_voucher_platform_base\`
          (\`voucher_id\`, \`platform\`, \`base_product_id\`)
      ) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4 COLLATE = utf8mb4_unicode_ci
    `);

    // iap_purchases.currency snapshots whatever the store charged, which can be
    // any ISO-4217 code (Play alone is live in 174 countries) — the old
    // enum('USD','VND') could not persist a JPY/KRW purchase at all.
    await queryRunner.query(`
      ALTER TABLE \`iap_purchases\`
        MODIFY COLUMN \`currency\` VARCHAR(3) NULL
          COMMENT 'ISO-4217 code snapshotted from the store at purchase time'
    `);

    await this.addColumnIfMissing(
      queryRunner,
      'iap_purchases',
      'original_transaction_id',
      "VARCHAR(255) NULL COMMENT 'Apple originalTransactionId; stable across renewals (order_id is per-transaction)'",
    );
    await this.addColumnIfMissing(
      queryRunner,
      'iap_purchases',
      'voucher_code',
      'VARCHAR(64) NULL',
    );
    await this.addColumnIfMissing(
      queryRunner,
      'iap_purchases',
      'voucher_discount_percent',
      'TINYINT UNSIGNED NULL',
    );
    await this.addColumnIfMissing(
      queryRunner,
      'iap_purchases',
      'country',
      'VARCHAR(64) NULL',
    );
    await this.addColumnIfMissing(
      queryRunner,
      'iap_purchases',
      'language',
      'VARCHAR(32) NULL',
    );

    await this.addIndexIfMissing(
      queryRunner,
      'iap_purchases',
      'IDX_iap_purchases_voucher_code',
      '(`voucher_code`)',
    );
  }

  public async down(queryRunner: QueryRunner): Promise<void> {
    await this.dropIndexIfPresent(
      queryRunner,
      'iap_purchases',
      'IDX_iap_purchases_voucher_code',
    );
    for (const column of [
      'language',
      'country',
      'voucher_discount_percent',
      'voucher_code',
      'original_transaction_id',
    ]) {
      await this.dropColumnIfPresent(queryRunner, 'iap_purchases', column);
    }
    await queryRunner.query(
      `ALTER TABLE \`iap_purchases\` MODIFY COLUMN \`currency\` ENUM('USD','VND') NULL`,
    );
    await queryRunner.query(
      `DROP TABLE IF EXISTS \`iap_voucher_product_mappings\``,
    );
    await queryRunner.query(`DROP TABLE IF EXISTS \`iap_vouchers\``);
  }

  private async columnExists(
    queryRunner: QueryRunner,
    table: string,
    column: string,
  ): Promise<boolean> {
    const rows = await queryRunner.query(
      `SELECT COUNT(*) AS total FROM information_schema.COLUMNS
        WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = ? AND COLUMN_NAME = ?`,
      [table, column],
    );
    return Number(rows?.[0]?.total ?? 0) > 0;
  }

  private async addColumnIfMissing(
    queryRunner: QueryRunner,
    table: string,
    column: string,
    definition: string,
  ): Promise<void> {
    if (await this.columnExists(queryRunner, table, column)) return;
    await queryRunner.query(
      `ALTER TABLE \`${table}\` ADD COLUMN \`${column}\` ${definition}`,
    );
  }

  private async dropColumnIfPresent(
    queryRunner: QueryRunner,
    table: string,
    column: string,
  ): Promise<void> {
    if (!(await this.columnExists(queryRunner, table, column))) return;
    await queryRunner.query(
      `ALTER TABLE \`${table}\` DROP COLUMN \`${column}\``,
    );
  }

  private async indexExists(
    queryRunner: QueryRunner,
    table: string,
    index: string,
  ): Promise<boolean> {
    const rows = await queryRunner.query(
      `SELECT COUNT(*) AS total FROM information_schema.STATISTICS
        WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = ? AND INDEX_NAME = ?`,
      [table, index],
    );
    return Number(rows?.[0]?.total ?? 0) > 0;
  }

  private async addIndexIfMissing(
    queryRunner: QueryRunner,
    table: string,
    index: string,
    columns: string,
  ): Promise<void> {
    if (await this.indexExists(queryRunner, table, index)) return;
    await queryRunner.query(
      `ALTER TABLE \`${table}\` ADD INDEX \`${index}\` ${columns}`,
    );
  }

  private async dropIndexIfPresent(
    queryRunner: QueryRunner,
    table: string,
    index: string,
  ): Promise<void> {
    if (!(await this.indexExists(queryRunner, table, index))) return;
    await queryRunner.query(
      `ALTER TABLE \`${table}\` DROP INDEX \`${index}\``,
    );
  }
}
