import { BadRequestException, Injectable } from '@nestjs/common';

import { RequestService } from '@base/service/request.service';
import { campaignKeyFor, isCampaignKey } from '@utils/promo-campaign.util';
import {
  normalizeCountryCodes,
  normalizeLocaleCodes,
} from '@utils/viewer-market.util';

import { UpdateHomeBannerConfigDto } from './dto/update-home-banner-config.dto';
import {
  eligibleSlidesFor,
  resolveConfiguredSlides,
  toVisibleSlides,
  VisibleSlide,
} from './home-banner.util';
import { HomeBannerConfigRepository } from './repository/home-banner-config.repository';
import { HomeBannerConfig } from './schema/home-banner-config.schema';
import {
  PromoStatRepository,
  PromoStatTotals,
} from '../promo-stats/repository/promo-stat.repository';
import { PromoKind } from '../promo-stats/schema/promo-stat.schema';
import { SegmentService } from '../segment/segment.service';

/**
 * What the endpoint returns: the stored config plus one field computed for
 * whoever is asking.
 *
 * `enabled` deliberately stays RAW. The admin panel reads this same endpoint,
 * so if `enabled` meant "on for you" it would show a live banner as switched
 * off whenever the operator happened to sit outside the target countries. One
 * field with two meanings depending on who asks is the kind of cleverness that
 * bites later; `visible` is a second field instead.
 */
export interface HomeBannerConfigView {
  enabled: boolean;
  imageUrl: string;
  linkUrl: string;
  countries: string[];
  visible: boolean;

  /**
   * The carousel this viewer should see, already filtered and in order.
   *
   * Empty means nothing to show -- same signal as `visible: false`, which is
   * kept for app builds that predate the carousel.
   */
  slides: VisibleSlide[];
}

/** One slide's stats row, aligned by index with the configured slides. */
export interface SlideStatsView extends PromoStatTotals {
  campaignKey: string;
}

@Injectable()
export class HomeBannerService {
  constructor(
    private readonly homeBannerConfigRepository: HomeBannerConfigRepository,
    private readonly promoStatRepository: PromoStatRepository,
    private readonly segmentService: SegmentService,
    private readonly requestService: RequestService,
  ) {}

  private get user() {
    return this.requestService.user;
  }

  /** Find-or-create the singleton config so this endpoint never 404s. */
  async getConfig(): Promise<HomeBannerConfig> {
    return this.homeBannerConfigRepository.findOrCreateDefault(this.user);
  }

  /**
   * The config as this particular caller should see it.
   *
   * `viewerMarkets` is resolved by the controller from request headers -- see
   * `resolveViewerMarkets`. It is every market the viewer plausibly belongs to
   * (IP country, device region, and the market their app language stands in
   * for), and targeting matches on ANY of them. Empty means we could place them
   * in no market at all, which hides a TARGETED banner and leaves an untargeted
   * one alone. `viewerLanguage` is the app language itself, for the per-slide
   * locale allow-list.
   */
  async getConfigFor(
    viewerMarkets: string[],
    viewerLanguage = '',
    viewerId = '',
  ): Promise<HomeBannerConfigView> {
    const config = await this.getConfig();

    let slides: VisibleSlide[] = [];
    if (config.enabled) {
      // Cheap request-answerable filters first; the segment check (it reads
      // the viewer) runs only on the survivors. `viewerId` is best-effort on
      // this @Public route — unknown viewers are hidden from segment-targeted
      // slides, exactly like the market rule.
      const eligible = eligibleSlidesFor(
        resolveConfiguredSlides(config),
        viewerMarkets,
        viewerLanguage,
      );
      const allowed = await this.segmentService.filterItemsForViewer(
        eligible,
        viewerId,
      );
      slides = toVisibleSlides(allowed);
    }

    // The first slide THIS viewer sees, mirrored into the single-banner fields.
    // App 1.5.0 is in production reading `imageUrl`/`linkUrl` and knows nothing
    // about slides; mirroring keeps it showing a banner AND keeps that banner
    // correctly targeted, which a stored value could not do.
    const [first] = slides;

    return {
      enabled: config.enabled,
      imageUrl: first?.imageUrl ?? '',
      linkUrl: first?.linkUrl ?? '',
      countries: config.countries ?? [],
      visible: slides.length > 0,
      slides,
    };
  }

  /**
   * The config exactly as stored -- for the admin panel -- plus one stats row
   * per configured slide, aligned by index.
   *
   * Deliberately NOT the same route the app reads. That one filters slides to
   * the caller's own markets, so an operator in Vietnam would open the page and
   * find a Japan-only slide missing, with nothing to say it had been filtered
   * rather than lost.
   */
  async getRawConfig(): Promise<
    HomeBannerConfig & { slideStats: SlideStatsView[] }
  > {
    const config = await this.getConfig();

    const keys = resolveConfiguredSlides(config).map(slide =>
      campaignKeyFor(slide.imageUrl, slide.linkUrl),
    );
    const totals = await this.promoStatRepository.totalsFor(
      PromoKind.BANNER,
      keys,
    );

    return {
      ...config,
      slideStats: keys.map(campaignKey => ({
        campaignKey,
        ...(totals[campaignKey] ?? { impressions: 0, clicks: 0, ctr: 0 }),
      })),
    };
  }

  /**
   * Count one impression or click against a slide's campaign.
   *
   * The key comes from the CLIENT (echoed from GET /home-banner), unvalidated
   * against the current config on purpose -- the viewer saw what they saw, and
   * a campaign published in the seconds since must not swallow their event.
   * The shape check keeps arbitrary client strings out of the collection.
   */
  async track(
    campaignKey: string,
    field: 'impressions' | 'clicks',
  ): Promise<{ recorded: boolean }> {
    const key = (campaignKey ?? '').trim();
    if (!isCampaignKey(key)) {
      throw new BadRequestException('campaignKey is not a valid campaign key');
    }

    await this.promoStatRepository.increment(PromoKind.BANNER, key, field);

    return { recorded: true };
  }

  /**
   * Partial update -- only the fields present in the body change. Sending
   * `{ enabled: false }` must not silently wipe the staged image or link.
   */
  async updateConfig(dto: UpdateHomeBannerConfigDto): Promise<HomeBannerConfig> {
    await this.getConfig();

    const patch: Partial<HomeBannerConfig> = {};
    if (dto.enabled !== undefined) patch.enabled = dto.enabled;
    if (dto.imageUrl !== undefined) patch.imageUrl = dto.imageUrl;
    if (dto.linkUrl !== undefined) patch.linkUrl = dto.linkUrl;
    // Normalised on WRITE so the matcher can stay a plain `includes`. Let 'vn'
    // reach Mongo and every read path would have to remember to upper-case --
    // and the one that forgot would simply never match, with nothing to show
    // for it.
    if (dto.countries !== undefined) {
      patch.countries = normalizeCountryCodes(dto.countries);
    }
    // Slides replace wholesale rather than merge: order IS the data here, and a
    // per-index merge could not express "delete the middle one".
    if (dto.slides !== undefined) {
      patch.slides = dto.slides.map(slide => ({
        name: (slide.name ?? '').trim(),
        imageUrl: (slide.imageUrl ?? '').trim(),
        linkUrl: (slide.linkUrl ?? '').trim(),
        countries: normalizeCountryCodes(slide.countries),
        locales: normalizeLocaleCodes(slide.locales),
        segmentIds: [
          ...new Set(
            (slide.segmentIds ?? []).map(id => id.trim()).filter(Boolean),
          ),
        ],
        priority: slide.priority ?? 0,
        startAt: slide.startAt ?? null,
        endAt: slide.endAt ?? null,
        // Absent means visible: a slide the admin never touched the switch on
        // is one they added to show.
        enabled: slide.enabled ?? true,
      }));
    }

    return this.homeBannerConfigRepository.upsertConfig(patch, this.user);
  }
}
