import { DownloadLink } from '../entities/download-link.entity';

export const APP_STORE_URL = 'https://apps.apple.com/app/id6755175330';
export const PLAY_STORE_URL =
  'https://play.google.com/store/apps/details?id=com.eup.meup';

/**
 * Where desktop visitors and unresolvable slugs land: the branded page served
 * by the `web` container. Never a 404 -- a printed link or QR code cannot be
 * recalled, so a wrong slug still has to end somewhere useful.
 */
export const FALLBACK_PAGE_URL = 'https://meup.training/tai-app';

/**
 * Google Play's `referrer` parameter survives the install and can be read back
 * by the app through the Install Referrer API. Nothing consumes it yet -- this
 * exists so links printed today stay useful if download attribution is added
 * later, rather than every campaign link having to be reissued.
 */
export function buildPlayUrl(link: DownloadLink): string {
  const parts: string[] = [];
  if (link.utmSource) parts.push(`utm_source=${encode(link.utmSource)}`);
  if (link.utmMedium) parts.push(`utm_medium=${encode(link.utmMedium)}`);
  if (link.utmCampaign) parts.push(`utm_campaign=${encode(link.utmCampaign)}`);
  // Always carry the slug so a click can be tied back to its link even when no
  // UTM values were filled in.
  parts.push(`utm_content=${encode(link.slug)}`);

  return `${PLAY_STORE_URL}&referrer=${encodeURIComponent(parts.join('&'))}`;
}

function encode(value: string): string {
  return encodeURIComponent(value);
}
