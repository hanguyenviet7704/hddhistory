// Mirrors meup-api src/modules/paywall-config/dto/paywall-config.dto.ts --
// keep both in sync if the backend contract changes.

export const PAYWALL_CONFIG_LOCALES = ["en", "vi", "zh", "ja", "ko"] as const;
export type PaywallLocale = (typeof PAYWALL_CONFIG_LOCALES)[number];

export const PAYWALL_CONFIG_LOCALE_LABELS: Record<PaywallLocale, string> = {
  en: "English",
  vi: "Tiếng Việt",
  zh: "中文",
  ja: "日本語",
  ko: "한국어",
};

export interface PaywallBenefit {
  icon: string;
  title: string;
}

/** One locale's worth of paywall copy (already in that locale). */
export interface PaywallLocaleContent {
  subheading?: string;
  heading?: string;
  benefits?: PaywallBenefit[];
}

/** `en` is required (i18n fallback locale); the other 4 are optional. */
export type PaywallLocalizedContent = {
  en: PaywallLocaleContent;
} & Partial<Record<Exclude<PaywallLocale, "en">, PaywallLocaleContent>>;

/**
 * A SKU pair the paywall can show. At least one of the two ids must be set --
 * enforced by the backend against `iap_products` (existence + isActive), not
 * by this shape.
 */
export interface PaywallProductRef {
  appleProductId?: string;
  googleProductId?: string;
}

/**
 * Which of a strategy's two SKU lists the paywall renders. `full` = `products`,
 * `compact` = `compactProducts`. The strategy owns the copy either way; this
 * only picks between its SKU lists.
 */
export type PaywallProductVariant = "full" | "compact";

/** Audience a sale event can target. */
export type PaywallAudienceSegment = "defaultUser" | "newUser";

export interface PaywallDefaultUser {
  content: PaywallLocalizedContent;
  products: PaywallProductRef[];
  /** Reduced list for `compact` entry points. Absent/empty falls back to `products`. */
  compactProducts?: PaywallProductRef[];
}

export interface PaywallImpressionRule {
  fromImpression: number;
  content: PaywallLocalizedContent;
  products: PaywallProductRef[];
  compactProducts?: PaywallProductRef[];
}

export interface PaywallNewUser {
  enabled: boolean;
  /** Required >= 1 by the backend when `enabled`: 0 puts every user in the default segment. */
  windowDays?: number;
  content?: PaywallLocalizedContent;
  impressionRules: PaywallImpressionRule[];
}

export interface PaywallSaleEvent {
  enabled: boolean;
  campaignId?: string;
  /** Both bounds required by the backend when `enabled` — the client drops a campaign missing either. */
  startAtUtc?: string;
  endAtUtc?: string;
  // Was `unknown` "round-tripped as-is", which let a bare `all` be saved. The
  // client reads this as a list of segment names and drops anything else, so
  // such a value silently meant "targets nobody".
  appliesTo?: PaywallAudienceSegment[];
  content?: PaywallLocalizedContent;
  products?: PaywallProductRef[];
  compactProducts?: PaywallProductRef[];
}

export interface PaywallSaleStrategy {
  defaultUser: PaywallDefaultUser;
  newUser: PaywallNewUser;
  saleEvent: PaywallSaleEvent;
}

/**
 * The two-step gift offer: a popup ("A special gift for you!") that opens a
 * bottom sheet headlined with `discountPercent` and a Claim Offer CTA.
 *
 * NOT part of `saleStrategy`: a sale event restyles the paywall the reader is
 * already on, while this interrupts with two surfaces of its own, on its own
 * schedule — the client drops an enabled campaign with no products, so the
 * Claim button can never point at nothing.
 */
export interface PaywallGiftCampaign {
  enabled: boolean;
  campaignId?: string;
  startAtUtc?: string;
  /** Campaign deadline AND the sheet countdown's source — one field, no drift. */
  endAtUtc?: string;
  /** Headline "N% OFF" only; the real price is the store product. 1-99. */
  discountPercent?: number;
  appliesTo?: PaywallAudienceSegment[];
  /** Copy for the popup step (heading only is read today). */
  popupContent?: PaywallLocalizedContent;
  /** Copy for the bottom-sheet step. */
  sheetContent?: PaywallLocalizedContent;
  /** SKU the Claim Offer button purchases. */
  products?: PaywallProductRef[];
}

export interface PaywallAutoOpen {
  enabled: boolean;
  sessionRolloutPercent: number;
}

/**
 * Opens the paywall from inside a keypoint, when the reader swipes off card 1
 * onto the next one. Optional on the wire: versions published before this gate
 * existed simply have no such key.
 */
export interface PaywallInLesson {
  enabled: boolean;
  /**
   * 1-based position among the course's KEYPOINTS in roadmap order; 0 = every
   * keypoint. Not the same ordering `lessonLock` counts in — the client used to
   * count lessons here despite the name.
   */
  keypointOrdinal?: number;
  /** Cards passed before it opens. 1 = leaving the first card. */
  afterCards?: number;
}

/**
 * Every place the app can open the paywall from. These strings are exactly the
 * Flutter `PaywallEntryPoint` enum's `.name` values -- the client looks a
 * variant up by that name, so they must match character for character.
 */
export const PAYWALL_ENTRY_POINTS = [
  "inLesson",
  "courseRoadmap",
  "autoOpen",
  "profile",
  "settingPre",
  "manageSubscription",
  "habit",
  "theme",
  "other",
] as const;
export type PaywallEntryPoint = (typeof PAYWALL_ENTRY_POINTS)[number];

export const PAYWALL_ENTRY_POINT_LABELS: Record<PaywallEntryPoint, string> = {
  inLesson: "Trong bài học (swipe qua thẻ keypoint)",
  courseRoadmap: "Roadmap khóa học (tap bài bị khóa)",
  autoOpen: "Tự động bật (Home / Explore)",
  profile: "Trang cá nhân",
  settingPre: "Cài đặt · thẻ Premium",
  manageSubscription: "Quản lý gói đăng ký",
  habit: "Habit · hết slot",
  theme: "Đổi hình nền học",
  other: "Khác",
};

/** Missing entry point ⇒ `full`, so the whole object may be absent. */
export type PaywallEntryPointVariants = Partial<
  Record<PaywallEntryPoint, PaywallProductVariant>
>;

export interface PaywallConfig {
  schemaVersion: number;
  enableLessonLock: boolean;
  /**
   * Lessons left free before the gate — a COUNT, matching the backend DTO and
   * the client's `int`. Was typed as a JSON blob here, which meant the editor
   * could never publish a usable value: valid JSON was rejected with a 400, and
   * leaving it blank dropped the key, which the client reads as 0 — locking the
   * course from lesson one, where the tap is swallowed rather than gated.
   */
  lessonLock?: number;
  autoOpen: PaywallAutoOpen;
  inLessonPaywall?: PaywallInLesson;
  entryPointVariants?: PaywallEntryPointVariants;
  saleStrategy: PaywallSaleStrategy;
  /** Optional so every version published before the campaign existed stays valid. */
  giftCampaign?: PaywallGiftCampaign;
  /** Laurel + store-rating strip under the plans. Absent means SHOWN. */
  showCredibilityBlock?: boolean;
}

// Mirrors meup-api dto/paywall-config-response.dto.ts. MySQL is now the
// source of truth (previously Firebase Remote Config's own
// `template.version`) -- `version` is a monotonically increasing integer
// starting at 1, append-only: publishing (or restoring) never mutates an
// existing row, it always writes a new, later version.
export interface PaywallConfigResponse {
  config: PaywallConfig;
  version: number;
  publishedAt: string;
  /** Publishing admin's user id/email, or the Remote Config seed sentinel. */
  publishedBy?: string;
}

/** One row of `GET /paywall-config/versions`, newest first. */
export interface PaywallConfigVersion extends PaywallConfigResponse {
  /** Whether this is the version currently served live. */
  isCurrent: boolean;
}

/** Field-level validation error, as produced by PaywallConfigService. */
export interface PaywallConfigValidationError {
  field: string;
  message: string;
}
