// The campaign-identity helpers were born here and moved to @utils when the
// banner's per-slide stats started keying on the same content hash. Re-exported
// so this module's imports (service, controller, specs) read as before.
export { campaignKeyFor, isCampaignKey } from '@utils/promo-campaign.util';

import {
  isVisibleInLocales,
  isVisibleInMarkets,
} from '@utils/viewer-market.util';

import {
  byPriority,
  isWithinWindow,
} from '../home-banner/home-banner.util';

/** One popup campaign as the admin configured it. */
export interface ConfiguredPopup {
  name?: string;
  imageUrl: string;
  linkUrl: string;
  countries?: string[];
  locales?: string[];
  segmentIds?: string[];
  priority?: number;
  startAt?: Date | null;
  endAt?: Date | null;
  enabled?: boolean;
  /** Bỏ qua đúng một bộ lọc: "người này bấm rồi". Xem schema. */
  alwaysShow?: boolean;
}

/**
 * The configured popup list, best first.
 *
 * The ONE place that knows the fallback rule: a config written before the
 * multi-campaign list existed has an empty `popups` and the single flat
 * creative, and that popup is item 1. Same trick as the banner's
 * `resolveConfiguredSlides` — it is what lets the list ship without a
 * migration and without an admin losing the campaign they already staged.
 */
export function resolveConfiguredPopups(config: {
  popups?: ConfiguredPopup[];
  imageUrl?: string;
  linkUrl?: string;
  countries?: string[];
}): ConfiguredPopup[] {
  if (config.popups && config.popups.length > 0) return config.popups;

  const imageUrl = (config.imageUrl ?? '').trim();
  if (!imageUrl) return [];

  return [
    {
      imageUrl,
      linkUrl: config.linkUrl ?? '',
      countries: config.countries ?? [],
      enabled: true,
      // Cấu hình cũ chưa từng có ô này, và mặc định phải giữ nguyên nết cũ:
      // bấm rồi là thôi.
      alwaysShow: false,
    },
  ];
}

/**
 * The popups this viewer could be shown, best first.
 *
 * Same filters as the banner (switch, image, market, language, window), then
 * priority order. The caller walks this list and shows the FIRST campaign the
 * user has not already tapped — so a lower-priority campaign gets its turn
 * once the top one is retired for that user, instead of being dead config.
 */
export function candidatePopupsFor(
  popups: ConfiguredPopup[],
  viewerMarkets: string[],
  viewerLanguage = '',
  now = new Date(),
): ConfiguredPopup[] {
  const visible = popups
    .filter(popup => popup.enabled !== false)
    .filter(popup => (popup.imageUrl ?? '').trim().length > 0)
    .filter(popup => isVisibleInMarkets(popup.countries, viewerMarkets))
    .filter(popup => isVisibleInLocales(popup.locales, viewerLanguage))
    .filter(popup => isWithinWindow(popup, now));

  return byPriority(visible);
}
