import { MigrationInterface, QueryRunner } from 'typeorm';

/**
 * `iap_purchases.paywall_experiment_key` + `paywall_body_variant` — which arm
 * of which paywall body A/B run the buyer purchased through, as the app
 * reported it at verify() time.
 *
 * Attribution only, exactly like `logic_sale_id` beside it: it never changes
 * the price, the product or the verify outcome. It exists because the A/B
 * readout must count VERIFIED orders and revenue per arm — client purchase
 * events include ones that were cancelled, failed or refunded, and an
 * experiment scored on those measures the wrong thing.
 *
 * Two columns rather than one packed string: the readout groups by arm within
 * a run, and a run's key has to stay readable after the config that defined it
 * has been superseded (paywall_configs is append-only, the key is not).
 *
 * Written once at INSERT and never backfilled onto renewals — a renewal verify
 * carries no assignment, so an arm is never credited for a sale that happened
 * long after its paywall was seen.
 *
 * Defensive like the migrations before it: the column check runs against
 * information_schema first, so a replay is a no-op. A failing migration stops
 * the app from booting (`migrationsRun: true` in mysql.module.ts).
 */
export class AddPurchasePaywallExperiment1787270400000
  implements MigrationInterface
{
  name = 'AddPurchasePaywallExperiment1787270400000';

  public async up(queryRunner: QueryRunner): Promise<void> {
    if (
      await this.columnExists(
        queryRunner,
        'iap_purchases',
        'paywall_experiment_key',
      )
    ) {
      return;
    }

    await queryRunner.query(`
      ALTER TABLE \`iap_purchases\`
        ADD COLUMN \`paywall_experiment_key\` VARCHAR(64) NULL
          COMMENT 'Paywall body A/B run the app reported at verify time. Attribution for the experiment readout only - never a discount',
        ADD COLUMN \`paywall_body_variant\` VARCHAR(16) NULL
          COMMENT 'Arm of that run: benefits | comparison',
        ADD INDEX \`IDX_iap_purchases_paywall_experiment\` (\`paywall_experiment_key\`, \`paywall_body_variant\`)
    `);
  }

  public async down(queryRunner: QueryRunner): Promise<void> {
    if (
      !(await this.columnExists(
        queryRunner,
        'iap_purchases',
        'paywall_experiment_key',
      ))
    ) {
      return;
    }

    await queryRunner.query(`
      ALTER TABLE \`iap_purchases\`
        DROP INDEX \`IDX_iap_purchases_paywall_experiment\`,
        DROP COLUMN \`paywall_experiment_key\`,
        DROP COLUMN \`paywall_body_variant\`
    `);
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
