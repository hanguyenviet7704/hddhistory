import { MigrationInterface, QueryRunner } from 'typeorm';

/**
 * Adds `iap_voucher_discount_tiers`, the table that turns an affiliate
 * discount PERCENTAGE into a purchasable store SKU.
 *
 * Background: promo codes now come from voucher.eup.ai rather than HDDhistory's own
 * `iap_vouchers` table. Their `/voucher/get` returns `{package_key, discount}`
 * pairs, but a percentage cannot be charged through IAP -- only a registered
 * SKU can. This table maps (package_key, platform, tier %) onto the SKU pair
 * to swap, declared once per tier instead of once per code so the affiliate
 * team can mint codes without anyone touching HDDhistory admin.
 *
 * `iap_vouchers` and `iap_voucher_product_mappings` are deliberately left in
 * place: they still hold the redemption history that `iap_purchases.
 * voucher_code` refers to, and dropping them would destroy it. They simply
 * stop being read by the validate path.
 *
 * Written defensively like AddPaywallConfigsTable1785232800000:
 * `CREATE TABLE IF NOT EXISTS` so re-running against an already-migrated
 * database is a no-op. A throwing migration stops the app from booting
 * (`migrationsRun: true` in mysql.module.ts).
 */
export class AddVoucherDiscountTiers1785801600000 implements MigrationInterface {
  name = 'AddVoucherDiscountTiers1785801600000';

  public async up(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(`
      CREATE TABLE IF NOT EXISTS \`iap_voucher_discount_tiers\` (
        \`id\`                VARCHAR(36)  NOT NULL,
        \`createdBy\`         VARCHAR(36)  NULL,
        \`updatedBy\`         VARCHAR(36)  NULL,
        \`createdAt\`         TIMESTAMP(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
        \`updatedAt\`         TIMESTAMP(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6)
                                ON UPDATE CURRENT_TIMESTAMP(6),
        \`package_key\`       VARCHAR(64)  NOT NULL
                                COMMENT 'Affiliate package key, e.g. pre1months. Keys with no row here are ignored.',
        \`platform\`          ENUM('google','apple') NOT NULL,
        \`discount_percent\`  TINYINT UNSIGNED NOT NULL
                                COMMENT 'The tier this row represents, 0-100',
        \`base_product_id\`   VARCHAR(255) NOT NULL
                                COMMENT 'SKU shown when no code applies',
        \`target_product_id\` VARCHAR(255) NOT NULL
                                COMMENT 'SKU to charge at this tier',
        PRIMARY KEY (\`id\`),
        UNIQUE KEY \`UQ_iap_voucher_discount_tiers_key_platform_percent\`
          (\`package_key\`, \`platform\`, \`discount_percent\`),
        KEY \`IDX_iap_voucher_discount_tiers_key_platform\`
          (\`package_key\`, \`platform\`),
        KEY \`IDX_iap_voucher_discount_tiers_platform_target\`
          (\`platform\`, \`target_product_id\`)
      ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
    `);
  }

  public async down(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(
      `DROP TABLE IF EXISTS \`iap_voucher_discount_tiers\``,
    );
  }
}
