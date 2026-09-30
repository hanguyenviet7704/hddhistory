import { MigrationInterface, QueryRunner } from 'typeorm';

/**
 * Shareable app-download links (`https://meup.training/r/<slug>`) and their
 * click log.
 *
 * Written defensively like the migrations before it -- `CREATE TABLE IF NOT
 * EXISTS`, so re-running against an already-migrated database is a no-op. A
 * failing migration stops the app from booting (`migrationsRun: true` in
 * mysql.module.ts), so these must be safe to replay.
 */
export class AddDownloadLinks1785317400000 implements MigrationInterface {
  name = 'AddDownloadLinks1785317400000';

  public async up(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(`
      CREATE TABLE IF NOT EXISTS \`app_download_links\` (
        \`id\`           VARCHAR(36)  NOT NULL,
        \`createdBy\`    VARCHAR(36)  NULL,
        \`updatedBy\`    VARCHAR(36)  NULL,
        \`createdAt\`    TIMESTAMP(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
        \`updatedAt\`    TIMESTAMP(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6)
                           ON UPDATE CURRENT_TIMESTAMP(6),
        \`slug\`         VARCHAR(64)  NOT NULL
                           COMMENT 'URL segment after /r/. Lowercase, trimmed',
        \`name\`         VARCHAR(255) NOT NULL
                           COMMENT 'Human label shown in admin, never public',
        \`description\`  VARCHAR(500) NULL,
        \`utm_source\`   VARCHAR(100) NULL,
        \`utm_medium\`   VARCHAR(100) NULL,
        \`utm_campaign\` VARCHAR(100) NULL,
        \`is_active\`    TINYINT(1)   NOT NULL DEFAULT 1,
        \`deleted_at\`   TIMESTAMP(6) NULL
                           COMMENT 'Soft delete: click rows reference this link and the history is the point of the feature',
        PRIMARY KEY (\`id\`),
        UNIQUE KEY \`UQ_app_download_links_slug\` (\`slug\`),
        KEY \`IDX_app_download_links_deleted_at\` (\`deleted_at\`)
      ) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4 COLLATE = utf8mb4_unicode_ci
    `);

    await queryRunner.query(`
      CREATE TABLE IF NOT EXISTS \`app_download_link_clicks\` (
        \`id\`         VARCHAR(36)  NOT NULL,
        \`createdBy\`  VARCHAR(36)  NULL,
        \`updatedBy\`  VARCHAR(36)  NULL,
        \`createdAt\`  TIMESTAMP(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
        \`updatedAt\`  TIMESTAMP(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6)
                         ON UPDATE CURRENT_TIMESTAMP(6),
        \`link_id\`    VARCHAR(36)  NOT NULL,
        \`platform\`   ENUM('ios','android','desktop','unknown')
                         NOT NULL DEFAULT 'unknown',
        \`country\`    CHAR(2)      NULL
                         COMMENT 'ISO-3166 alpha-2 from Cloudflare CF-IPCountry',
        \`referer\`    VARCHAR(500) NULL,
        \`user_agent\` VARCHAR(500) NULL,
        \`ip_hash\`    CHAR(64)     NULL
                         COMMENT 'SHA-256 of client IP + DOWNLOAD_LINK_IP_SALT. NULL when no salt is configured -- never an unsalted hash, which IPv4 makes reversible',
        \`clicked_at\` TIMESTAMP(6) NOT NULL,
        PRIMARY KEY (\`id\`),
        KEY \`IDX_app_download_link_clicks_link_time\` (\`link_id\`, \`clicked_at\`),
        KEY \`IDX_app_download_link_clicks_clicked_at\` (\`clicked_at\`)
      ) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4 COLLATE = utf8mb4_unicode_ci
    `);
  }

  public async down(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(
      `DROP TABLE IF EXISTS \`app_download_link_clicks\``,
    );
    await queryRunner.query(`DROP TABLE IF EXISTS \`app_download_links\``);
  }
}
