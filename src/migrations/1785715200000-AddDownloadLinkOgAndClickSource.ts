import { MigrationInterface, QueryRunner } from 'typeorm';

/**
 * Two additions to the download-link feature:
 *
 * 1. `app_download_links.og_*` — the preview card (title/description/image)
 *    served as OG tags to link-preview crawlers, so a link shared on
 *    Facebook/Threads/TikTok/Zalo renders its own campaign card instead of
 *    nothing (crawlers reject the data:-URI image the generic page embeds).
 * 2. `app_download_link_clicks.source` — which app/site the click came from,
 *    detected from User-Agent tokens and the Referer host. Old rows stay
 *    'unknown'; the raw UA/referer they carry were never classified.
 *
 * Written defensively like the migrations before it: column checks run
 * against information_schema first, so a replay is a no-op. A failing
 * migration stops the app from booting (`migrationsRun: true` in
 * mysql.module.ts).
 */
export class AddDownloadLinkOgAndClickSource1785715200000
  implements MigrationInterface
{
  name = 'AddDownloadLinkOgAndClickSource1785715200000';

  public async up(queryRunner: QueryRunner): Promise<void> {
    if (!(await this.columnExists(queryRunner, 'app_download_links', 'og_title'))) {
      await queryRunner.query(`
        ALTER TABLE \`app_download_links\`
          ADD COLUMN \`og_title\` VARCHAR(255) NULL
            COMMENT 'Preview-card title served to link crawlers. NULL = generic card',
          ADD COLUMN \`og_description\` VARCHAR(500) NULL,
          ADD COLUMN \`og_image\` VARCHAR(500) NULL
            COMMENT 'Absolute https URL, ideally 1200x630. Crawlers reject data: URIs'
      `);
    }

    if (
      !(await this.columnExists(queryRunner, 'app_download_link_clicks', 'source'))
    ) {
      await queryRunner.query(`
        ALTER TABLE \`app_download_link_clicks\`
          ADD COLUMN \`source\` ENUM(
            'facebook','instagram','threads','tiktok','zalo','telegram',
            'google','direct','other','unknown'
          ) NOT NULL DEFAULT 'unknown'
            COMMENT 'App or site the click came from, from UA tokens then Referer host. unknown = pre-migration row'
            AFTER \`platform\`
      `);
    }
  }

  public async down(queryRunner: QueryRunner): Promise<void> {
    if (await this.columnExists(queryRunner, 'app_download_links', 'og_title')) {
      await queryRunner.query(`
        ALTER TABLE \`app_download_links\`
          DROP COLUMN \`og_title\`,
          DROP COLUMN \`og_description\`,
          DROP COLUMN \`og_image\`
      `);
    }

    if (
      await this.columnExists(queryRunner, 'app_download_link_clicks', 'source')
    ) {
      await queryRunner.query(
        `ALTER TABLE \`app_download_link_clicks\` DROP COLUMN \`source\``,
      );
    }
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
