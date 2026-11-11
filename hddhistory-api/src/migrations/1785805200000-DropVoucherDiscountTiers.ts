import { MigrationInterface, QueryRunner } from 'typeorm';

/**
 * Drops `iap_voucher_discount_tiers` again, one commit after
 * AddVoucherDiscountTiers1785801600000 created it.
 *
 * Why it went away: the table existed to map an affiliate `package_key` onto a
 * store SKU pair, on the assumption that `package_key` was an abstract key
 * needing translation (the spec sheet's examples were `pre1months`,
 * `pre12months`). The live service says otherwise — for HDDhistory it answers with
 * the SKU itself (`meup_sub_1y_50off`), and the base-SKU half was already in
 * `iap_products.compare_at_product_id`, which admin surfaces as "Giá gốc so
 * sánh (SKU)". So every row would have restated data the catalogue already
 * held, by hand, with a second place to get wrong.
 *
 * `validate` now derives both halves from `iap_products` directly. The table
 * was never populated, so nothing is lost.
 *
 * Kept as a forward migration rather than by deleting the create-migration:
 * 1785801600000 already ran on dev, and removing its file would leave the table
 * orphaned there with no record of why.
 */
export class DropVoucherDiscountTiers1785805200000
  implements MigrationInterface
{
  name = 'DropVoucherDiscountTiers1785805200000';

  public async up(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(
      `DROP TABLE IF EXISTS \`iap_voucher_discount_tiers\``,
    );
  }

  public async down(queryRunner: QueryRunner): Promise<void> {
    // Mirror of AddVoucherDiscountTiers1785801600000.up, so a rollback of this
    // migration leaves the schema as that one left it.
    await queryRunner.query(`
      CREATE TABLE IF NOT EXISTS \`iap_voucher_discount_tiers\` (
        \`id\`                VARCHAR(36)  NOT NULL,
        \`createdBy\`         VARCHAR(36)  NULL,
        \`updatedBy\`         VARCHAR(36)  NULL,
        \`createdAt\`         TIMESTAMP(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
        \`updatedAt\`         TIMESTAMP(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6)
                                ON UPDATE CURRENT_TIMESTAMP(6),
        \`package_key\`       VARCHAR(64)  NOT NULL,
        \`platform\`          ENUM('google','apple') NOT NULL,
        \`discount_percent\`  TINYINT UNSIGNED NOT NULL,
        \`base_product_id\`   VARCHAR(255) NOT NULL,
        \`target_product_id\` VARCHAR(255) NOT NULL,
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
}
