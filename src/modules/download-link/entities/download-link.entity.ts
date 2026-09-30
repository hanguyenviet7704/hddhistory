import { Column, DeleteDateColumn, Entity, Index } from 'typeorm';

import { AbstractEntity } from '@base/database/mysql/abstract.entity';

/**
 * One shareable download link, e.g. `https://meup.training/r/zalo-thang-8`.
 *
 * Lives on the apex domain on purpose: `Runner.entitlements` declares
 * `applinks:meup.training` with no wildcard, so a link on any subdomain would
 * stop opening the app for people who already have it installed.
 */
@Entity({ name: 'app_download_links' })
export class DownloadLink extends AbstractEntity {
  @Column({
    type: 'varchar',
    length: 64,
    unique: true,
    comment: 'URL segment after /r/. Lowercase, stored trimmed',
  })
  slug: string;

  @Column({
    type: 'varchar',
    length: 255,
    comment: 'Human label shown in admin, never public',
  })
  name: string;

  @Column({ type: 'varchar', length: 500, nullable: true })
  description?: string;

  // Folded into Google Play's `referrer` parameter, which survives the install
  // and can be read back by the app later. App Store ignores unknown query
  // params, so the same values are harmless there.
  @Column({ name: 'utm_source', type: 'varchar', length: 100, nullable: true })
  utmSource?: string;

  @Column({ name: 'utm_medium', type: 'varchar', length: 100, nullable: true })
  utmMedium?: string;

  @Column({
    name: 'utm_campaign',
    type: 'varchar',
    length: 100,
    nullable: true,
  })
  utmCampaign?: string;

  // The preview card chat apps and social feeds render when this link is
  // shared. Served to their crawlers as OG tags straight from /r/<slug>, so
  // every campaign can carry its own title/image. All optional: an empty field
  // falls back to the generic HDDhistory card.
  @Column({ name: 'og_title', type: 'varchar', length: 255, nullable: true })
  ogTitle?: string;

  @Column({
    name: 'og_description',
    type: 'varchar',
    length: 500,
    nullable: true,
  })
  ogDescription?: string;

  @Column({
    name: 'og_image',
    type: 'varchar',
    length: 500,
    nullable: true,
    comment:
      'Absolute https URL, ideally 1200x630. Crawlers reject data: URIs, ' +
      'which is why this can never be an embedded image',
  })
  ogImage?: string;

  @Column({
    name: 'is_active',
    type: 'boolean',
    default: true,
    comment:
      'Inactive links still resolve -- they fall through to the generic ' +
      'download page rather than 404, because a printed link or QR code ' +
      'cannot be recalled',
  })
  isActive: boolean;

  // Soft delete: click rows reference this link, and a hard delete would throw
  // away the history that is the whole point of the feature.
  @Index()
  @DeleteDateColumn({ name: 'deleted_at', type: 'timestamp', nullable: true })
  deletedAt?: Date;
}
