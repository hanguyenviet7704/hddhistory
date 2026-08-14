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
  saleEvent: PaywallSaleEvent;
}

/**
 * One free-text line, per locale, with the same contract as
 * `PaywallLocalizedContent`: en required, rest optional. Shared by the two
 * single-line spots on the paywall (the gift popup's title, the compact
 * sheet's urgency line) that don't need the full subheading/heading/benefits
 * shape.
 */
export type PaywallLocalizedLine = {
  en: string;
} & Partial<Record<Exclude<PaywallLocale, "en">, string>>;

/**
 * The gift popup: its only job is to open the COMPACT paywall on a schedule
 * hardcoded in the app (first habit on day 0, first open of each day 1-7,
 * premium users skipped). Everything the reader sees after the tap belongs to
 * the compact paywall's own config (see `PaywallCompactPaywall` /
 * `compactProducts` below) — the ONLY thing configurable here is the popup's
 * title line; absent falls back to the app's bundled copy ("A special gift
 * for you!"). The CTA label ("Open") is hardcoded too.
 */
export interface PaywallGiftCampaign {
  enabled: boolean;
  /** Popup title per locale. Absent uses the app's bundled copy. */
  title?: PaywallLocalizedLine;
  /** Days after day zero the daily-open popup keeps running. Absent = 7. */
  windowDays?: number;
  /** Show when the reader adopts their first habit (day 0). Absent = on. */
  triggerOnFirstHabit?: boolean;
  /** Show on the first app open of each day in the window. Absent = on. */
  triggerOnDailyOpen?: boolean;
}

/**
 * Config owned by the compact paywall itself (the "33% OFF"-style one-plan
 * sheet). SKUs stay per-strategy (`compactProducts`) and the discount/
 * countdown come from the sale event that is currently winning — this only
 * carries copy that belongs to the sheet itself.
 */
export interface PaywallCompactPaywall {
  /** Headline "N% OFF" — display only; the charge is the compact SKU's price. */
  discountPercent?: number;
  /**
   * Line under the discount headline. Absent uses the app's bundled copy
   * ("You will never see this again if you exit"); shown only while a sale
   * event is running.
   */
  urgencyLine?: PaywallLocalizedLine;
}

/** One locale's worth of one review card's text (already in that locale). */
export interface PaywallReviewLocaleContent {
  title?: string;
  body?: string;
}

/** Same locale contract as `PaywallLocalizedContent`: en required, rest optional. */
export type PaywallReviewContent = {
  en: PaywallReviewLocaleContent;
} & Partial<Record<Exclude<PaywallLocale, "en">, PaywallReviewLocaleContent>>;

/**
 * One card of the paywall's "What people say" carousel. Name and avatar are
 * shown as-is in every locale (a reviewer's name is not translated); only the
 * card's text is per-locale.
 */
export interface PaywallReview {
  name: string;
  /** Absolute image URL. Absent renders an initial-letter placeholder. */
  avatarUrl?: string;
  /** 1-5 stars. Absent means 5. */
  rating?: number;
  content: PaywallReviewContent;
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
/**
 * Free-tier daily reading quota: one keypoint a day, read in full; every other
 * keypoint that day stops at `afterCards`.
 *
 * REPLACES `inLessonPaywall` rather than joining it — the two ask different
 * questions (where a keypoint sits in the course vs how much the reader has read
 * today) and running both leaves a lock nobody can explain.
 *
 * Unlike every other block here it is NOT enforceable on the client: it depends on
 * the reader's own history, so the server decides and the app is told the cap.
 */
export interface PaywallDailyKeypointQuota {
  enabled: boolean;
  /** Keypoints readable in full per day. 1 in the design. */
  freeKeypointsPerDay?: number;
  /** Card the lock stands at once the ticket is spent. 3 = two cards readable. */
  afterCards?: number;
}

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

/**
 * A merchandising rule layered on top of the base sale strategy: independently
 * scheduled, targeted at a segment, and carrying its own SKU list that
 * overrides the winning strategy's plan list while it applies. `id` is the
 * STABLE attribution key purchases are counted by — generated once client-side
 * when the row is created, never reused even after the row is removed.
 */
export interface PaywallLogicSale {
  id: string;
  name: string;
  enabled: boolean;
  /** Empty/absent = every user. ANY match, same contract as the promo campaigns' segmentIds. */
  segmentIds?: string[];
  /**
   * Plans offered while this rule applies, overriding the strategy's SKU list
   * on the app's full paywall. Empty/absent = staged, never served.
   */
  products?: PaywallProductRef[];
  /** Higher wins when several LogicSales apply at once; ties keep list order. */
  priority?: number;
  startAtUtc?: string;
  endAtUtc?: string;
  /** Show a countdown to `endAtUtc` on the paywall. Requires `endAtUtc` to be set. */
  countdown?: boolean;
}

/** One row of `GET /paywall-config/logic-sales/:id/stats` — never sum across rows, currencies don't add up. */
export interface PaywallLogicSaleStatsByProduct {
  productId: string;
  /** null when no order has settled a currency for this product yet. */
  currency: string | null;
  orders: number;
  paidRevenue: number;
  refundedRevenue: number;
  netRevenue: number;
}

/** GET /paywall-config/logic-sales/:id/stats response — read-only, fetched on demand. */
export interface PaywallLogicSaleStats {
  id: string;
  totalOrders: number;
  /** Empty = no orders yet for this logic sale. */
  byProduct: PaywallLogicSaleStatsByProduct[];
}

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
  /** Optional so every version published before this gate existed stays valid. */
  dailyKeypointQuota?: PaywallDailyKeypointQuota;
  entryPointVariants?: PaywallEntryPointVariants;
  saleStrategy: PaywallSaleStrategy;
  /** Optional so every version published before this section existed stays valid. */
  compactPaywall?: PaywallCompactPaywall;
  /** Optional so every version published before the campaign existed stays valid. */
  giftCampaign?: PaywallGiftCampaign;
  /** Laurel + store-rating strip under the plans. Absent means SHOWN. */
  showCredibilityBlock?: boolean;
  /** The "What people say" carousel. Absent falls back to the app's bundled reviews. */
  reviews?: PaywallReview[];
  /**
   * Merchandising rules layered on the base sale strategy, max 20. Optional so
   * every version published before this existed stays valid.
   */
  logicSales?: PaywallLogicSale[];
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
