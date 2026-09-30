import { MigrationInterface, QueryRunner } from 'typeorm';

/**
 * New table for Part 2 of
 * plans/260727-voucher-paywall-config-affiliate/design.md — per-territory
 * store prices, synced from Apple/Google, purely for staff visibility in the
 * admin "Regional Prices" table (never sent to the app as the displayed
 * price).
 *
 * Written defensively like AddVoucherAndPurchaseColumns1785110400000:
 * `CREATE TABLE IF NOT EXISTS` so re-running against an already-migrated
 * database is a no-op rather than an error — a failing migration would stop
 * the app from booting (`migrationsRun: true` in mysql.module.ts).
 */
export class AddIapProductPrices1785114000000 implements MigrationInterface {
  name = 'AddIapProductPrices1785114000000';

  public async up(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(`
      CREATE TABLE IF NOT EXISTS \`iap_product_prices\` (
        \`id\`             VARCHAR(36)  NOT NULL,
        \`createdBy\`      VARCHAR(36)  NULL,
        \`updatedBy\`      VARCHAR(36)  NULL,
        \`createdAt\`      TIMESTAMP(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
        \`updatedAt\`      TIMESTAMP(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6)
                             ON UPDATE CURRENT_TIMESTAMP(6),
        \`product_id\`     VARCHAR(255) NOT NULL
                             COMMENT 'iap_products.productId (the SKU) -- not a foreign key, prices can be synced before/after the catalog row exists',
        \`platform\`       ENUM('google','apple') NOT NULL,
        \`territory\`      VARCHAR(8)   NOT NULL
                             COMMENT 'Territory code exactly as returned by the source store -- ISO 3166-1 alpha-3 for Apple (e.g. AUS), alpha-2 region code for Google (e.g. AU). Never normalized across stores.',
        \`currency\`       VARCHAR(3)   NOT NULL COMMENT 'ISO-4217 code',
        \`customer_price\` DOUBLE       NOT NULL
                             COMMENT 'READ-ONLY / staff visibility only -- never send to the app as the displayed price, the app reads the live localized price from StoreKit/Play at purchase time',
        \`source\`         ENUM('google','apple') NOT NULL,
        \`synced_at\`      TIMESTAMP(6) NOT NULL,
        PRIMARY KEY (\`id\`),
        UNIQUE KEY \`UQ_iap_product_prices_product_platform_territory\`
          (\`product_id\`, \`platform\`, \`territory\`)
      ) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4 COLLATE = utf8mb4_unicode_ci
    `);
  }

  public async down(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(`DROP TABLE IF EXISTS \`iap_product_prices\``);
  }
}
