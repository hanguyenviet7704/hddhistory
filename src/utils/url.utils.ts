/**
 * URL handling for the one consumer that is stricter than the web: FCM.
 *
 * `firebase-admin` runs its own `isURL` over every image URL in a message and
 * rejects the WHOLE message when it fails — and because `sendEach` validates
 * inside its per-message map, that rejection comes back as a per-token
 * `messaging/invalid-payload` instead of one thrown error. A campaign whose
 * artwork was uploaded as `Pop up (1).png` therefore reads as "every device
 * failed", with nothing in the log naming the image (2026-09-10: 2279 failures,
 * 0 sent).
 *
 * The uploader keeps spaces in R2 object keys, so such URLs are ordinary and
 * will keep arriving from pasted links too. Both are handled here rather than
 * at the upload site alone: encoding at send time also repairs every URL
 * already stored.
 */

/**
 * Everything `firebase-admin`'s validator tolerates anywhere in a URL. `%` is
 * included on purpose — that is what keeps an already-encoded URL from being
 * encoded a second time (`%20` must not become `%2520`).
 */
const SAFE_ANYWHERE = /[A-Za-z0-9:/?#[\]@!$&'()*+,;=.\-_~%]/;

/** Its hostname rule: dot-separated zones, none opening with `-` or `_`. */
const SAFE_HOSTNAME = /^[a-zA-Z0-9]+[\w-]*([.]?[a-zA-Z0-9]+[\w-]*)*$/;

/** Its pathname rule — narrower than [SAFE_ANYWHERE]: no `&`, `?` or `#`. */
const SAFE_PATHNAME = /^(\/[\w\-.~!$'()*+,;=:@%]+)*\/?$/;

/**
 * Percent-encodes only the characters FCM refuses, leaving existing escapes
 * alone. Iterates code POINTS, so an emoji or a Vietnamese filename survives as
 * valid UTF-8 rather than as two broken halves.
 */
export function encodeUrlForPush(url: string): string {
  return Array.from(url)
    .map(character =>
      SAFE_ANYWHERE.test(character)
        ? character
        : encodeURIComponent(character),
    )
    .join('');
}

/** Mirrors `firebase-admin`'s own `isURL`, which is what actually gates a send. */
export function isPushSafeUrl(url: string): boolean {
  if (Array.from(url).some(character => !SAFE_ANYWHERE.test(character))) {
    return false;
  }

  try {
    const parsed = new URL(url);
    if (parsed.protocol !== 'http:' && parsed.protocol !== 'https:') {
      return false;
    }
    if (!SAFE_HOSTNAME.test(parsed.hostname)) return false;
    return (
      parsed.pathname === '' ||
      parsed.pathname === '/' ||
      SAFE_PATHNAME.test(parsed.pathname)
    );
  } catch {
    return false;
  }
}

/**
 * The URL to actually put in a push, or null when no encoding can save it.
 *
 * Null means "send this notification without artwork": a push that arrives as
 * text beats a push that never arrives, which is what returning the bad URL
 * would cost.
 */
export function toPushSafeUrl(url?: string | null): string | null {
  const trimmed = (url ?? '').trim();
  if (!trimmed) return null;

  const encoded = encodeUrlForPush(trimmed);
  return isPushSafeUrl(encoded) ? encoded : null;
}
