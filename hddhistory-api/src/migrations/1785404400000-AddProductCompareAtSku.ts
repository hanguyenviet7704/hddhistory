import { MigrationInterface, QueryRunner } from 'typeorm';

/**
 * `iap_products.compare_at_product_id` — the SKU whose real store price the
 * paywall strikes through above the selling price. Stores a SKU reference
 * rather than an amount so the struck price stays localized per storefront
 * (Apple alone prices in 175 territories) and can never drift from the real
 * charge.
 *
 * Written defensively like the migrations before it: the column check runs
 * against information_schema first, so a replay is a no-op. A failing
 * migration stops the app from booting (`migrationsRun: true` in
 * mysql.module.ts).
 */
export class AddProductCompareAtSku1785404400000 implements MigrationInterface {
  name = 'AddProductCompareAtSku1785404400000';

  public async up(queryRunner: QueryRunner): Promise<void> {
    if (
      await this.columnExists(
        queryRunner,
        'iap_products',
        'compare_at_product_id',
      )
    ) {
      return;
    }

    await queryRunner.query(`
      ALTER TABLE \`iap_products\`
        ADD COLUMN \`compare_at_product_id\` VARCHAR(255) NULL
          COMMENT 'SKU on the same platform whose real store price is struck through above this one. A reference, not an amount. NULL = no struck price'
    `);
  }

  public async down(queryRunner: QueryRunner): Promise<void> {
    if (
      !(await this.columnExists(
        queryRunner,
        'iap_products',
        'compare_at_product_id',
      ))
    ) {
      return;
    }

    await queryRunner.query(
      `ALTER TABLE \`iap_products\` DROP COLUMN \`compare_at_product_id\``,
    );
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
}
