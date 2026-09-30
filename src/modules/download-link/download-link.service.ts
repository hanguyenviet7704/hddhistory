import { createHash } from 'crypto';

import {
  BadRequestException,
  Injectable,
  Logger,
  NotFoundException,
} from '@nestjs/common';

import { Configuration } from '@base/config/configuration';
import { RequestService } from '@base/service/request.service';

import { CreateDownloadLinkDto } from './dto/create-download-link.dto';
import {
  GetDownloadLinkStatsDto,
  GetListDownloadLinkDto,
} from './dto/get-download-link.dto';
import { UpdateDownloadLinkDto } from './dto/update-download-link.dto';
import { DownloadLink } from './entities/download-link.entity';
import { ClickPlatform } from './enum/download-link.enum';
import {
  detectPlatform,
  detectSource,
  isCrawler,
} from './helpers/client-detect';
import { renderOgPreviewHtml } from './helpers/og-preview';
import {
  APP_STORE_URL,
  FALLBACK_PAGE_URL,
  buildPlayUrl,
} from './helpers/store-targets';
import { DownloadLinkClickRepository } from './repositories/download-link-click.repository';
import { DownloadLinkRepository } from './repositories/download-link.repository';

export interface ClickContext {
  userAgent?: string;
  ip?: string;
  country?: string;
  referer?: string;
}

/**
 * What the redirect controller should answer: a 302 for people, an OG-tag
 * preview page for link crawlers. Kept as data so the service never touches
 * the HTTP response object.
 */
export type ResolveResult =
  | { kind: 'redirect'; url: string }
  | { kind: 'preview'; html: string };

@Injectable()
export class DownloadLinkService {
  private readonly logger = new Logger(DownloadLinkService.name);

  constructor(
    private readonly linkRepository: DownloadLinkRepository,
    private readonly clickRepository: DownloadLinkClickRepository,
    private readonly configService: Configuration,
    private readonly requestService: RequestService,
  ) {}

  private get user() {
    return this.requestService.user;
  }

  // ---- admin ----

  async findAll(dto: GetListDownloadLinkDto) {
    const page = await this.linkRepository.findOption(dto);
    const totals = await this.linkRepository.countClicksByLinkIds(
      page.items.map((item) => item.id),
    );

    return {
      ...page,
      items: page.items.map((item) => ({
        ...item,
        totalClicks: totals.get(item.id) ?? 0,
      })),
    };
  }

  async findOne(id: string): Promise<DownloadLink> {
    const link = await this.linkRepository.findById(id);
    if (!link) throw new NotFoundException('Download link not found');
    return link;
  }

  async create(dto: CreateDownloadLinkDto) {
    const existing = await this.linkRepository.findBySlug(dto.slug);
    if (existing) {
      throw new BadRequestException(`Slug "${dto.slug}" is already in use`);
    }
    return this.linkRepository.create(dto, this.user?.id);
  }

  async update(id: string, dto: UpdateDownloadLinkDto) {
    await this.findOne(id);
    await this.linkRepository.updateById(id, dto, this.user?.id);
    return this.findOne(id);
  }

  async remove(id: string): Promise<void> {
    await this.findOne(id);
    await this.linkRepository.softDeleteById(id);
  }

  async stats(id: string, dto: GetDownloadLinkStatsDto) {
    const link = await this.findOne(id);
    const { from, to } = this.resolveRange(dto);

    const [total, unique, byDay, byPlatform, byCountry, bySource] =
      await Promise.all([
        this.clickRepository.countInRange(id, from, to),
        this.clickRepository.countUniqueInRange(id, from, to),
        this.clickRepository.groupByDay(id, from, to),
        this.clickRepository.groupByPlatform(id, from, to),
        this.clickRepository.groupByCountry(id, from, to),
        this.clickRepository.groupBySource(id, from, to),
      ]);

    return {
      link,
      range: { from, to },
      total,
      // Null rather than 0 when no salt is configured, so the UI can say
      // "not measured" instead of showing a confident, wrong zero.
      unique: this.configService.getDownloadLinkIpSalt ? unique : null,
      byDay,
      byPlatform,
      byCountry,
      bySource,
    };
  }

  // ---- public redirect ----

  /**
   * Resolves a slug to what the visitor should get: a store redirect for
   * people, an OG-tag preview page for link crawlers (Facebook, Threads,
   * TikTok, Zalo...). Crawlers used to be 302'd like everyone else, which
   * meant every campaign shared the generic download page's preview card.
   *
   * Never throws for the visitor's sake: an unknown, inactive or deleted slug
   * still returns the generic download page (or generic preview). A link that
   * has been printed on a flyer or turned into a QR code cannot be corrected,
   * so a dead end there is permanent.
   */
  async resolveAndRecord(
    slug: string,
    context: ClickContext,
  ): Promise<ResolveResult> {
    const normalizedSlug = slug.trim().toLowerCase();
    const link = await this.linkRepository.findBySlug(normalizedSlug);
    const activeLink = link && link.isActive ? link : null;

    // Crawlers get the preview page and are never counted -- one shared post
    // triggers a fetch from every platform it lands on.
    if (isCrawler(context.userAgent)) {
      return {
        kind: 'preview',
        html: renderOgPreviewHtml(normalizedSlug, activeLink),
      };
    }

    if (!activeLink) return { kind: 'redirect', url: FALLBACK_PAGE_URL };

    const platform = detectPlatform(context.userAgent);

    // Recording must never cost the visitor a redirect. A DB blip should
    // lose one number, not strand someone on an error page.
    try {
      await this.clickRepository.record({
        linkId: activeLink.id,
        platform,
        source: detectSource(context.userAgent, context.referer),
        country: context.country?.slice(0, 2)?.toUpperCase() || null,
        referer: context.referer?.slice(0, 500),
        userAgent: context.userAgent?.slice(0, 500),
        ipHash: this.hashIp(context.ip),
        clickedAt: new Date(),
      });
    } catch (error: any) {
      this.logger.error(
        `Failed to record click for slug=${slug}: ${error?.message}`,
        error?.stack,
      );
    }

    switch (platform) {
      case ClickPlatform.IOS:
        return { kind: 'redirect', url: APP_STORE_URL };
      case ClickPlatform.ANDROID:
        return { kind: 'redirect', url: buildPlayUrl(activeLink) };
      default:
        return { kind: 'redirect', url: FALLBACK_PAGE_URL };
    }
  }

  private hashIp(ip?: string): string | null {
    const salt = this.configService.getDownloadLinkIpSalt;
    if (!salt || !ip) return null;
    return createHash('sha256').update(`${salt}:${ip}`).digest('hex');
  }

  private resolveRange(dto: GetDownloadLinkStatsDto): { from: Date; to: Date } {
    const to = dto.to ? new Date(dto.to) : new Date();
    to.setHours(23, 59, 59, 999);

    const from = dto.from
      ? new Date(dto.from)
      : new Date(to.getTime() - 29 * 24 * 60 * 60 * 1000);
    from.setHours(0, 0, 0, 0);

    if (from > to) {
      throw new BadRequestException('`from` must not be after `to`');
    }
    return { from, to };
  }
}
