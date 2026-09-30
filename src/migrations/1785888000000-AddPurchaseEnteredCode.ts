import { MigrationInterface, QueryRunner } from 'typeorm';

/**
 * `iap_purchases.entered_code` — the promo/affiliate code the buyer actually
 * typed, stored whether or not it resolves to a row in `iap_vouchers`.
 *
 * `voucher_code` cannot carry this: it means "a voucher that validated and was
 * redeemed" and is counted by `countPaidByUserAndVoucherCode` to enforce
 * `per_user_limit`, so putting unregistered codes in it would charge them
 * against a limit they were never subject to. The affiliate feed reads the
 * entered code and falls back to the voucher one for rows written before this.
 *
 * Written defensively like the migrations before it: the column check runs
 * against information_schema first, so a replay is a no-op. A failing
 * migration stops the app from booting (`migrationsRun: true` in
 * mysql.module.ts).
 */
export class AddPurchaseEnteredCode1785888000000 implements MigrationInterface {
  name = 'AddPurchaseEnteredCode1785888000000';

  public async up(queryRunner: QueryRunner): Promise<void> {
    if (await this.columnExists(queryRunner, 'iap_purchases', 'entered_code')) {
      return;
    }

    await queryRunner.query(`
      ALTER TABLE \`iap_purchases\`
        ADD COLUMN \`entered_code\` VARCHAR(64) NULL
          COMMENT 'Promo/affiliate code as typed by the buyer, kept even when it matches no voucher. Attribution only - never grants a discount',
        ADD INDEX \`IDX_iap_purchases_entered_code\` (\`entered_code\`)
    `);
  }

  public async down(queryRunner: QueryRunner): Promise<void> {
    if (
      !(await this.columnExists(queryRunner, 'iap_purchases', 'entered_code'))
    ) {
      return;
    }

    await queryRunner.query(
      `ALTER TABLE \`iap_purchases\` DROP COLUMN \`entered_code\``,
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
