import { encodeUrlForPush } from '@utils/url.utils';

/**
 * One place that decides what "no image" means for a notification.
 *
 * Campaign and template both accept an image the same way — a URL the admin
 * uploaded to R2 — and both need the empty string to mean "clear it", because
 * that is what a Xoá ảnh button sends. Leaving each service to trim on its own
 * is how one of them ends up storing `''` and sending an FCM message with an
 * empty `imageUrl`, which Firebase rejects for the whole batch rather than
 * ignoring.
 */
export function normalizeNotificationImageUrl(
  imageUrl?: string | null,
): string | null {
  const trimmed = (imageUrl ?? '').trim();
  if (trimmed.length === 0) return null;

  // Stored already encoded, so the URL admin shows back is the URL that will be
  // sent. Encoding only -- never dropping: a URL this cannot save is still the
  // operator's own input, and losing it silently on save is worse than the send
  // path noticing it later (see `toPushSafeUrl`, which is the gate that matters).
  return encodeUrlForPush(trimmed);
}
