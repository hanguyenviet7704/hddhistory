import { BadRequestException, Injectable } from '@nestjs/common';

import { RequestService } from '@base/service/request.service';
import { campaignKeyFor, isCampaignKey } from '@utils/promo-campaign.util';
import {
  normalizeCountryCodes,
  normalizeLocaleCodes,
} from '@utils/viewer-market.util';

import { ClickHomePopupDto } from './dto/click-home-popup.dto';
import { UpdateHomePopupConfigDto } from './dto/update-home-popup-config.dto';
import {
  candidatePopupsFor,
  resolveConfiguredPopups,
} from './home-popup.util';
import { HomePopupClickRepository } from './repository/home-popup-click.repository';
import { HomePopupConfigRepository } from './repository/home-popup-config.repository';
import { HomePopupConfig } from './schema/home-popup-config.schema';
import {
  PromoStatRepository,
  PromoStatTotals,
} from '../promo-stats/repository/promo-stat.repository';
import { PromoKind } from '../promo-stats/schema/promo-stat.schema';
import { SegmentService } from '../segment/segment.service';

/**
 * What the app receives.
 *
 * Still ONE popup, whatever the config now holds: the server walks the
 * campaign list and answers with the best one for this viewer, so the app
 * contract never changed when the list shipped. `enabled` stays RAW for the
 * same reason the banner's does -- one field with two meanings depending on who
 * asks bites later. `visible` is the computed one, and it already accounts for
 * the market, the language, the campaign window and this user having tapped
 * before, so the app decides nothing.
 */
export interface HomePopupView {
  enabled: boolean;
  imageUrl: string;
  linkUrl: string;
  /** Identity of the creative; echoed back on tap. Empty when there is none. */
  campaignKey: string;
  visible: boolean;
}

/** One campaign's stats row, aligned by index with the configured popups. */
export interface PopupStatsView extends PromoStatTotals {
  campaignKey: string;
}

@Injectable()
export class HomePopupService {
  constructor(
    private readonly configRepository: HomePopupConfigRepository,
    private readonly clickRepository: HomePopupClickRepository,
    private readonly promoStatRepository: PromoStatRepository,
    private readonly segmentService: SegmentService,
    private readonly requestService: RequestService,
  ) {}

  private get user() {
    return this.requestService.user;
  }

  private get userId(): string {
    return this.user?.id ?? '';
  }

  /** Find-or-create the singleton config so this endpoint never 404s. */
  async getConfig(): Promise<HomePopupConfig> {
    return this.configRepository.findOrCreateDefault(this.user);
  }

  /**
   * The popup as this caller should see it.
   *
   * The campaign list is filtered (switch, image, market, language, window),
   * ordered by priority, and walked until a campaign this user has NOT tapped
   * turns up -- so a lower-priority campaign gets its turn once the top one is
   * retired for them, instead of being dead config. The app is told the answer
   * rather than the inputs.
   *
   * Click lookups run only for campaigns that survived the cheap filters, and
   * only for signed-in users -- a guest has no click history to consult.
   */
  async getPopupFor(
    viewerMarkets: string[],
    viewerLanguage = '',
  ): Promise<HomePopupView> {
    const config = await this.getConfig();

    let candidates = config.enabled
      ? candidatePopupsFor(
          resolveConfiguredPopups(config),
          viewerMarkets,
          viewerLanguage,
        )
      : [];
    // Segment targeting runs on the survivors of the cheap filters only. This
    // route is authed, so the viewer is always known here.
    if (candidates.length > 0) {
      candidates = await this.segmentService.filterItemsForViewer(
        candidates,
        this.userId,
      );
    }

    let chosenKey = '';
    let chosen: (typeof candidates)[number] | undefined;
    for (const candidate of candidates) {
      const campaignKey = campaignKeyFor(candidate.imageUrl, candidate.linkUrl);
      // `alwaysShow` skips the click lookup rather than ignoring its answer:
      // the row is still written when they tap (CTR counts those rows), it
      // just stops being a reason to retire the campaign. Skipping the query
      // also keeps the walk cheap for the campaign that never retires.
      const alreadyClicked =
        this.userId && !candidate.alwaysShow
          ? await this.clickRepository.hasClicked(this.userId, campaignKey)
          : false;
      if (!alreadyClicked) {
        chosen = candidate;
        chosenKey = campaignKey;
        break;
      }
    }

    return {
      enabled: config.enabled,
      // The chosen campaign mirrored into the flat fields -- the shipped app
      // reads exactly these and knows nothing about the list.
      imageUrl: chosen?.imageUrl?.trim() ?? '',
      linkUrl: chosen?.linkUrl?.trim() ?? '',
      campaignKey: chosenKey,
      visible: Boolean(chosen),
    };
  }

  /**
   * Records that this user tapped a campaign, which retires the popup for them.
   *
   * Takes the key from the body, unvalidated against the CURRENT config on
   * purpose: the user tapped what they were shown, and a campaign published in
   * the seconds since must not be marked as seen on their behalf. The shape check
   * is what keeps an arbitrary client string out of the collection.
   */
  async markClicked(dto: ClickHomePopupDto): Promise<{ recorded: boolean }> {
    const campaignKey = dto.campaignKey.trim();
    if (!isCampaignKey(campaignKey)) {
      throw new BadRequestException('campaignKey is not a valid campaign key');
    }

    // The stat counter moves for guests too -- a tap is a tap. The per-user
    // retirement below still needs an identity to retire for.
    await this.promoStatRepository.increment(
      PromoKind.POPUP,
      campaignKey,
      'clicks',
    );

    // No user, nothing to remember. Not an error: the app fires this without
    // waiting for it, and failing here would only produce noise in the logs.
    if (!this.userId) return { recorded: false };

    await this.clickRepository.markClicked(this.userId, campaignKey, this.user);

    return { recorded: true };
  }

  /** The popup was SHOWN to someone. Fire-and-forget from the app. */
  async trackImpression(dto: ClickHomePopupDto): Promise<{ recorded: boolean }> {
    const campaignKey = dto.campaignKey.trim();
    if (!isCampaignKey(campaignKey)) {
      throw new BadRequestException('campaignKey is not a valid campaign key');
    }

    await this.promoStatRepository.increment(
      PromoKind.POPUP,
      campaignKey,
      'impressions',
    );

    return { recorded: true };
  }

  /**
   * The config exactly as stored -- for the admin panel, which must not be handed
   * a `visible` computed against the operator's own market or click history --
   * plus one stats row per configured campaign, aligned by index.
   */
  async getRawConfig(): Promise<
    HomePopupConfig & { campaignKey: string; popupStats: PopupStatsView[] }
  > {
    const config = await this.getConfig();

    const keys = resolveConfiguredPopups(config).map(popup =>
      campaignKeyFor(popup.imageUrl, popup.linkUrl),
    );
    const totals = await this.promoStatRepository.totalsFor(
      PromoKind.POPUP,
      keys,
    );

    return {
      ...config,
      // Shown in admin so an operator can tell at a glance whether an edit
      // started a new campaign. Kept for the panel that predates the list.
      campaignKey: campaignKeyFor(config.imageUrl, config.linkUrl),
      popupStats: keys.map(campaignKey => ({
        campaignKey,
        ...(totals[campaignKey] ?? { impressions: 0, clicks: 0, ctr: 0 }),
      })),
    };
  }

  /** Partial update -- only the fields present in the body change. */
  async updateConfig(dto: UpdateHomePopupConfigDto): Promise<HomePopupConfig> {
    await this.getConfig();

    const patch: Partial<HomePopupConfig> = {};
    if (dto.enabled !== undefined) patch.enabled = dto.enabled;
    if (dto.imageUrl !== undefined) patch.imageUrl = dto.imageUrl.trim();
    if (dto.linkUrl !== undefined) patch.linkUrl = dto.linkUrl.trim();
    // Normalised on WRITE so the matcher stays a plain `includes`.
    if (dto.countries !== undefined) {
      patch.countries = normalizeCountryCodes(dto.countries);
    }
    // The list replaces wholesale, same rule as the banner slides: order is
    // data, and a per-index merge could not express deleting a middle row.
    if (dto.popups !== undefined) {
      patch.popups = dto.popups.map(popup => ({
        name: (popup.name ?? '').trim(),
        imageUrl: (popup.imageUrl ?? '').trim(),
        linkUrl: (popup.linkUrl ?? '').trim(),
        countries: normalizeCountryCodes(popup.countries),
        locales: normalizeLocaleCodes(popup.locales),
        segmentIds: [
          ...new Set(
            (popup.segmentIds ?? []).map(id => id.trim()).filter(Boolean),
          ),
        ],
        priority: popup.priority ?? 0,
        startAt: popup.startAt ?? null,
        endAt: popup.endAt ?? null,
        enabled: popup.enabled ?? true,
        alwaysShow: popup.alwaysShow ?? false,
      }));
    }

    return this.configRepository.upsertConfig(patch, this.user);
  }
}
