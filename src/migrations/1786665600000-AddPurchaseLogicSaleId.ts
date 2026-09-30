import { MigrationInterface, QueryRunner } from 'typeorm';

/**
 * `iap_purchases.logic_sale_id` — which paywall LogicSale campaign the buyer
 * purchased through, as the app reported it at verify() time.
 *
 * Attribution only, exactly like `entered_code` beside it: it never changes
 * the price or the product, it is what lets the admin's LogicSale statistics
 * count orders and revenue per campaign per plan. Written once at INSERT and
 * never backfilled onto renewals — a renewal verify carries no logicSaleId,
 * so a campaign is never credited for a sale it had no part in.
 *
 * Written defensively like the migrations before it: the column check runs
 * against information_schema first, so a replay is a no-op. A failing
 * migration stops the app from booting (`migrationsRun: true` in
 * mysql.module.ts).
 */
export class AddPurchaseLogicSaleId1786665600000 implements MigrationInterface {
  name = 'AddPurchaseLogicSaleId1786665600000';

  public async up(queryRunner: QueryRunner): Promise<void> {
    if (
      await this.columnExists(queryRunner, 'iap_purchases', 'logic_sale_id')
    ) {
      return;
    }

    await queryRunner.query(`
      ALTER TABLE \`iap_purchases\`
        ADD COLUMN \`logic_sale_id\` VARCHAR(64) NULL
          COMMENT 'Paywall LogicSale campaign the app reported at verify time. Attribution for the campaign statistics only - never a discount',
        ADD INDEX \`IDX_iap_purchases_logic_sale_id\` (\`logic_sale_id\`)
    `);
  }

  public async down(queryRunner: QueryRunner): Promise<void> {
    if (
      !(await this.columnExists(queryRunner, 'iap_purchases', 'logic_sale_id'))
    ) {
      return;
    }

    await queryRunner.query(
      `ALTER TABLE \`iap_purchases\` DROP COLUMN \`logic_sale_id\``,
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
