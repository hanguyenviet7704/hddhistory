import { createHash } from 'crypto';

/**
 * Identity of a promotional CREATIVE, not of the config document that holds it.
 *
 * A short hash of the image and link. Everything about how a campaign behaves
 * over time falls out of this one choice:
 *
 * - Change the image or the link and the key changes, so a viewer who tapped the
 *   previous campaign is offered the new one, and stat counters start fresh. No
 *   admin has to remember to bump a version, which is the failure mode of every
 *   "campaign id" field: forget it once and the new campaign silently never
 *   reaches the people most likely to convert.
 * - Restore a previous creative and the key comes back with it, so the people who
 *   already acted on that exact offer are not asked twice — and its stat history
 *   resumes. A counter could not express either.
 * - Toggling `enabled`, editing the market list, or reordering slides does NOT
 *   change it: none of those change what is being offered.
 *
 * Born on the Home popup, now shared by the Home banner's per-slide stats.
 * Empty when there is no image, because then there is no campaign to identify.
 */
export function campaignKeyFor(imageUrl?: string, linkUrl?: string): string {
  const image = (imageUrl ?? '').trim();
  if (!image) return '';

  const link = (linkUrl ?? '').trim();

  // 16 hex chars of sha1 -- short enough to read in a log, far past collision
  // range for a handful of campaigns, and stable across processes (which a JS
  // string hash would also be, but this one is obviously so).
  return createHash('sha1').update(`${image}|${link}`).digest('hex').slice(0, 16);
}

/** Shape a campaign key must have to be accepted from a client. */
const CAMPAIGN_KEY = /^[0-9a-f]{16}$/;

/**
 * Whether `key` is something [[campaignKeyFor]] could have produced.
 *
 * The tracking endpoints take the key from the CLIENT rather than recomputing
 * it, so that a tap records the creative the user actually saw rather than
 * whatever the admin published in the seconds since. That makes it a
 * client-supplied value landing in a database, so it is bounded here to exactly
 * the shape we emit.
 */
export function isCampaignKey(key?: string): boolean {
  return CAMPAIGN_KEY.test((key ?? '').trim());
}
