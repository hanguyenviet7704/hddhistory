import { FALLBACK_PAGE_URL } from './store-targets';
import { DownloadLink } from '../entities/download-link.entity';


/**
 * Shipped by the `web-download-link` container next to index.html. Kept as a
 * URL, never a data: URI -- Facebook, TikTok, Zalo and friends all refuse
 * embedded images, which is exactly the bug this file exists to fix.
 */
export const DEFAULT_OG_IMAGE_URL = 'https://meup.training/og-image.png';

const DEFAULT_OG_TITLE = 'Tải HDDhistory';
const DEFAULT_OG_DESCRIPTION = 'Học kỹ năng mềm mỗi ngày.';

/** Same host the entitlements claim -- see DownloadLinkRedirectController. */
const PUBLIC_LINK_BASE = 'https://meup.training/r';

/**
 * The page link-preview crawlers see instead of the 302 humans get.
 *
 * A crawler that is 302'd to the generic download page renders the same
 * generic card for every campaign; answering it here lets each link carry its
 * own title/description/image. The meta refresh is a safety net for the rare
 * real person whose browser matches the crawler pattern (HeadlessChrome,
 * scripts) -- they still end up on the download page.
 */
export function renderOgPreviewHtml(
  slug: string,
  link: DownloadLink | null,
): string {
  const title = escapeHtml(link?.ogTitle?.trim() || DEFAULT_OG_TITLE);
  const description = escapeHtml(
    link?.ogDescription?.trim() || DEFAULT_OG_DESCRIPTION,
  );
  const image = escapeHtml(link?.ogImage?.trim() || DEFAULT_OG_IMAGE_URL);
  const url = escapeHtml(`${PUBLIC_LINK_BASE}/${slug}`);
  const fallback = escapeHtml(FALLBACK_PAGE_URL);

  return `<!doctype html>
<html lang="vi">
<head>
<meta charset="utf-8">
<title>${title}</title>
<meta name="description" content="${description}">
<meta property="og:type" content="website">
<meta property="og:site_name" content="HDDhistory">
<meta property="og:title" content="${title}">
<meta property="og:description" content="${description}">
<meta property="og:image" content="${image}">
<meta property="og:url" content="${url}">
<meta name="twitter:card" content="summary_large_image">
<meta http-equiv="refresh" content="0; url=${fallback}">
</head>
<body>
<p><a href="${fallback}">${title}</a></p>
</body>
</html>
`;
}

function escapeHtml(value: string): string {
  return value
    .replace(/&/g, '&amp;')
    .replace(/</g, '&lt;')
    .replace(/>/g, '&gt;')
    .replace(/"/g, '&quot;')
    .replace(/'/g, '&#39;');
}
