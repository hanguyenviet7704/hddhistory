import { MigrationInterface, QueryRunner } from 'typeorm';

/**
 * `iap_code_attributions` — a promo/affiliate code recorded the moment a user
 * APPLIES it, so a purchase can still be attributed when the app never got to
 * hand the code over (killed on the store sheet, a failed verify, Ask-to-Buy
 * completing hours later).
 *
 * Written defensively like the migrations before it: the existence check runs
 * against information_schema first, so a replay is a no-op. A failing
 * migration stops the app from booting (`migrationsRun: true` in
 * mysql.module.ts).
 */
export class AddCodeAttributions1785896400000 implements MigrationInterface {
  name = 'AddCodeAttributions1785896400000';

  public async up(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(`
      CREATE TABLE IF NOT EXISTS \`iap_code_attributions\` (
        \`id\`                       VARCHAR(36)  NOT NULL,
        \`createdBy\`                VARCHAR(36)  NULL,
        \`updatedBy\`                VARCHAR(36)  NULL,
        \`createdAt\`                TIMESTAMP(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
        \`updatedAt\`                TIMESTAMP(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6)
                                       ON UPDATE CURRENT_TIMESTAMP(6),
        \`user_id\`                  VARCHAR(64)  NOT NULL,
        \`code\`                     VARCHAR(64)  NOT NULL
                                       COMMENT 'As typed, trimmed + uppercased',
        \`consumed_at\`              TIMESTAMP(6) NULL
                                       COMMENT 'Set when a purchase took this code; single-use on purpose',
        \`consumed_by_purchase_id\`  VARCHAR(64)  NULL
                                       COMMENT 'iap_purchases.id that took it',
        PRIMARY KEY (\`id\`),
        KEY \`IDX_iap_code_attributions_user_unconsumed\` (\`user_id\`, \`consumed_at\`)
      ) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4 COLLATE = utf8mb4_unicode_ci
    `);
  }

  public async down(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(
      `DROP TABLE IF EXISTS \`iap_code_attributions\``,
    );
  }
}
