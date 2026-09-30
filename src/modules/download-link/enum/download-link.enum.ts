/** Which store a click was sent to, derived from the request's User-Agent. */
export enum ClickPlatform {
  IOS = 'ios',
  ANDROID = 'android',
  DESKTOP = 'desktop',
  UNKNOWN = 'unknown',
}

/**
 * Where the click came from -- the app or site the visitor was in when they
 * tapped the link. Derived from the User-Agent first (in-app webviews name
 * themselves there and usually send no Referer) and the Referer host second.
 */
export enum ClickSource {
  FACEBOOK = 'facebook',
  INSTAGRAM = 'instagram',
  THREADS = 'threads',
  TIKTOK = 'tiktok',
  ZALO = 'zalo',
  TELEGRAM = 'telegram',
  GOOGLE = 'google',
  /** No referer and no in-app token: typed, QR code, or a chat that hides it. */
  DIRECT = 'direct',
  /** A referer was sent but the host is not one we classify. */
  OTHER = 'other',
  /** Rows recorded before source detection existed. */
  UNKNOWN = 'unknown',
}
