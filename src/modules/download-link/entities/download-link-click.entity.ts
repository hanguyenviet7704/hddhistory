import { Column, Entity, Index } from 'typeorm';

import { AbstractEntity } from '@base/database/mysql/abstract.entity';

import { ClickPlatform, ClickSource } from '../enum/download-link.enum';

/**
 * One row per click that reached the server.
 *
 * Deliberately NOT a complete picture: people who already have the app never
 * hit this endpoint at all, because iOS/Android hand `meup.training/*` straight
 * to the app (AASA `paths: ["*"]`). These numbers describe reach among people
 * WITHOUT the app -- which is what a download link is for -- and must not be
 * read as total link traffic.
 */
@Index(['linkId', 'clickedAt'])
@Entity({ name: 'app_download_link_clicks' })
export class DownloadLinkClick extends AbstractEntity {
  @Column({ name: 'link_id', type: 'uuid' })
  linkId: string;

  @Column({
    type: 'enum',
    enum: ClickPlatform,
    default: ClickPlatform.UNKNOWN,
  })
  platform: ClickPlatform;

  @Column({
    type: 'enum',
    enum: ClickSource,
    default: ClickSource.UNKNOWN,
    comment:
      'App or site the click came from, detected from User-Agent tokens ' +
      'first (in-app webviews send no Referer) then the Referer host. ' +
      'unknown = recorded before this column existed',
  })
  source: ClickSource;

  @Column({
    type: 'char',
    length: 2,
    nullable: true,
    comment: "ISO-3166 alpha-2 from Cloudflare's CF-IPCountry header",
  })
  country?: string;

  @Column({ type: 'varchar', length: 500, nullable: true })
  referer?: string;

  @Column({
    name: 'user_agent',
    type: 'varchar',
    length: 500,
    nullable: true,
  })
  userAgent?: string;

  @Column({
    name: 'ip_hash',
    type: 'char',
    length: 64,
    nullable: true,
    comment:
      'SHA-256 of the client IP + a server-side salt. Never the raw IP: the ' +
      'hash is enough to count unique clickers without storing personal data',
  })
  ipHash?: string;

  @Index()
  @Column({ name: 'clicked_at', type: 'timestamp' })
  clickedAt: Date;
}
