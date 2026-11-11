import { campaignKeyFor } from '@utils/promo-campaign.util';
import {
  isVisibleInLocales,
  isVisibleInMarkets,
} from '@utils/viewer-market.util';

/** A slide as the admin configured it. */
export interface ConfiguredSlide {
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
}

/**
 * A slide as the app receives it -- already filtered, so nothing to decide.
 *
 * `campaignKey` is the content hash the popup click system already uses as
 * campaign identity (`campaignKeyFor`): the app echoes it back on the
 * impression/click tracking posts, so stats survive reordering and follow the
 * CREATIVE rather than an array position.
 */
export interface VisibleSlide {
  campaignKey: string;
  imageUrl: string;
  linkUrl: string;
}

/**
 * The configured carousel, in display order.
 *
 * The ONE place that knows the fallback rule, so no other path has to remember
 * it: a config written before the carousel existed has an empty `slides` and a
 * single `imageUrl`, and that banner is its slide 1. This is what lets the
 * carousel ship without a migration and without an admin losing the campaign
 * they already staged.
 */
export function resolveConfiguredSlides(config: {
  slides?: ConfiguredSlide[];
  imageUrl?: string;
  linkUrl?: string;
  countries?: string[];
}): ConfiguredSlide[] {
  if (config.slides && config.slides.length > 0) return config.slides;

  const imageUrl = (config.imageUrl ?? '').trim();
  if (!imageUrl) return [];

  return [
    {
      imageUrl,
      linkUrl: config.linkUrl ?? '',
      countries: config.countries ?? [],
      enabled: true,
    },
  ];
}

/**
 * Whether a campaign window contains `now`.
 *
 * Null bounds are open on purpose — existing slides have neither field and
 * must keep showing exactly as before, and "no end date" is the common case
 * for an evergreen banner.
 */
export function isWithinWindow(
  item: { startAt?: Date | null; endAt?: Date | null },
  now: Date,
): boolean {
  if (item.startAt && now < new Date(item.startAt)) return false;
  if (item.endAt && now > new Date(item.endAt)) return false;

  return true;
}

/**
 * Higher `priority` first, ties keeping the given order — so the array order
 * stays the "thứ tự treo" and priority is an override, not a replacement.
 * `sort` is stable in modern V8, which is what makes the tie rule true.
 */
export function byPriority<T extends { priority?: number }>(items: T[]): T[] {
  return [...items].sort((a, b) => (b.priority ?? 0) - (a.priority ?? 0));
}

/**
 * The slides this viewer should see, in order.
 *
 * Filtering on the SERVER rather than shipping the whole carousel and letting
 * the app choose is what makes the dots honest: the app draws one dot per slide
 * it was given, so a viewer in Vietnam counts only the slides meant for Vietnam.
 * It also keeps campaign targeting out of a client that could be old.
 *
 * A slide with no image is dropped rather than rendered as a hole -- the admin
 * adds a row before uploading its image, and a half-filled row must not become
 * a blank slide with a dot of its own.
 */
export function visibleSlidesFor(
  slides: ConfiguredSlide[],
  viewerMarkets: string[],
  viewerLanguage = '',
  now = new Date(),
): VisibleSlide[] {
  return toVisibleSlides(
    eligibleSlidesFor(slides, viewerMarkets, viewerLanguage, now),
  );
}

/**
 * The cheap, synchronous filters only — everything answerable from the
 * request itself. Split from [[toVisibleSlides]] so the SEGMENT check (async:
 * it reads the viewer) can run between them, on the few slides that survive,
 * instead of on the whole roster.
 */
export function eligibleSlidesFor(
  slides: ConfiguredSlide[],
  viewerMarkets: string[],
  viewerLanguage = '',
  now = new Date(),
): ConfiguredSlide[] {
  return slides
    .filter(slide => slide.enabled !== false)
    .filter(slide => (slide.imageUrl ?? '').trim().length > 0)
    .filter(slide => isVisibleInMarkets(slide.countries, viewerMarkets))
    .filter(slide => isVisibleInLocales(slide.locales, viewerLanguage))
    .filter(slide => isWithinWindow(slide, now));
}

/** Order the survivors and strip them to what the app receives. */
export function toVisibleSlides(slides: ConfiguredSlide[]): VisibleSlide[] {
  return byPriority(slides).map(slide => ({
    campaignKey: campaignKeyFor(slide.imageUrl, slide.linkUrl),
    imageUrl: slide.imageUrl.trim(),
    linkUrl: (slide.linkUrl ?? '').trim(),
  }));
}
