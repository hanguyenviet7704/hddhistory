import { ClickPlatform, ClickSource } from '../enum/download-link.enum';

/**
 * Link-preview crawlers. When someone pastes a link into Zalo, Messenger or
 * Telegram, the chat app fetches the URL itself to build a preview card --
 * that hit reaches this endpoint and would otherwise be counted as a click,
 * inflating every number the moment a link is shared.
 *
 * Deliberately narrow. `FBAN`/`FBAV` (Facebook's in-app BROWSER) and the plain
 * `Zalo` token are NOT here: those are real people reading inside a webview,
 * and dropping them would undercount the single most common way links travel
 * in Vietnam.
 */
const CRAWLER_PATTERN = new RegExp(
  [
    'facebookexternalhit',
    'facebookcatalog',
    'Facebot',
    'Twitterbot',
    'WhatsApp',
    'TelegramBot',
    'Slackbot',
    'SkypeUriPreview',
    'LinkedInBot',
    'Discordbot',
    'Applebot',
    'Googlebot',
    'bingbot',
    'YandexBot',
    'DuckDuckBot',
    'redditbot',
    'Pinterest',
    'ZaloPC-{0,1}\\w*Bot',
    'Go-http-client',
    'python-requests',
    'curl/',
    'Wget/',
    'HeadlessChrome',
    '\\bbot\\b',
    'crawler',
    'spider',
  ].join('|'),
  'i',
);

export function isCrawler(userAgent?: string): boolean {
  if (!userAgent) return true; // no UA at all is a script, not a person
  return CRAWLER_PATTERN.test(userAgent);
}

export function detectPlatform(userAgent?: string): ClickPlatform {
  if (!userAgent) return ClickPlatform.UNKNOWN;

  if (/iPhone|iPad|iPod/i.test(userAgent)) return ClickPlatform.IOS;
  if (/Android/i.test(userAgent)) return ClickPlatform.ANDROID;
  // iPadOS 13+ reports itself as a Mac. Unlike the browser, the server cannot
  // check maxTouchPoints, so these land in DESKTOP and get the chooser page --
  // which still offers the App Store button, so nobody is stranded.
  if (/Macintosh|Windows|Linux|CrOS/i.test(userAgent)) {
    return ClickPlatform.DESKTOP;
  }
  return ClickPlatform.UNKNOWN;
}

/**
 * In-app webviews name their host app in the User-Agent and usually send no
 * Referer at all, so the UA is checked first. Order matters: the Threads app
 * ships Instagram's engine ("Barcelona" is Threads' internal codename) and
 * Instagram in turn carries Meta tokens, so the most specific token wins.
 */
const UA_SOURCES: Array<[RegExp, ClickSource]> = [
  [/Barcelona/i, ClickSource.THREADS],
  [/Instagram/i, ClickSource.INSTAGRAM],
  [/FBAN|FBAV|FB_IAB|FB4A|FBIOS|FBBV/i, ClickSource.FACEBOOK],
  [/musical_ly|Bytedance|TikTok/i, ClickSource.TIKTOK],
  [/Zalo/i, ClickSource.ZALO],
  [/Telegram/i, ClickSource.TELEGRAM],
];

/**
 * Referer hosts for clicks made in a regular browser (or the few in-app
 * browsers that do send one). `l.facebook.com`, `lm.instagram.com` and the
 * like are covered by matching on the registrable domain suffix.
 */
const REFERER_SOURCES: Array<[RegExp, ClickSource]> = [
  [/(^|\.)(facebook\.com|fb\.com|fb\.me|messenger\.com)$/i, ClickSource.FACEBOOK],
  [/(^|\.)instagram\.com$/i, ClickSource.INSTAGRAM],
  [/(^|\.)(threads\.net|threads\.com)$/i, ClickSource.THREADS],
  [/(^|\.)tiktok\.com$/i, ClickSource.TIKTOK],
  [/(^|\.)(zalo\.me|zaloapp\.com)$/i, ClickSource.ZALO],
  [/(^|\.)(t\.me|telegram\.org|telegram\.me)$/i, ClickSource.TELEGRAM],
  [/(^|\.)google\.[a-z.]+$/i, ClickSource.GOOGLE],
];

export function detectSource(
  userAgent?: string,
  referer?: string,
): ClickSource {
  if (userAgent) {
    for (const [pattern, source] of UA_SOURCES) {
      if (pattern.test(userAgent)) return source;
    }
  }

  const host = refererHost(referer);
  if (host) {
    for (const [pattern, source] of REFERER_SOURCES) {
      if (pattern.test(host)) return source;
    }
    return ClickSource.OTHER;
  }

  return ClickSource.DIRECT;
}

function refererHost(referer?: string): string | null {
  if (!referer) return null;
  try {
    return new URL(referer).hostname;
  } catch {
    return null;
  }
}
