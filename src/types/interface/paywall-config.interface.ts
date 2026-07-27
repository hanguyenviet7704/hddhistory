import { PaywallEnvironment } from "../enum/paywall-config.enum";

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

export interface PaywallDefaultUser {
  content: PaywallLocalizedContent;
  products: PaywallProductRef[];
}

export interface PaywallImpressionRule {
  fromImpression: number;
  content: PaywallLocalizedContent;
  products: PaywallProductRef[];
}

export interface PaywallNewUser {
  enabled: boolean;
  windowDays?: number;
  content?: PaywallLocalizedContent;
  impressionRules: PaywallImpressionRule[];
}

export interface PaywallSaleEvent {
  enabled: boolean;
  campaignId?: string;
  startAtUtc?: string;
  endAtUtc?: string;
  // Shape not fixed upstream -- round-tripped as-is (see backend DTO comment).
  appliesTo?: unknown;
  content?: PaywallLocalizedContent;
  products?: PaywallProductRef[];
}

export interface PaywallSaleStrategy {
  defaultUser: PaywallDefaultUser;
  newUser: PaywallNewUser;
  saleEvent: PaywallSaleEvent;
}

export interface PaywallAutoOpen {
  enabled: boolean;
  sessionRolloutPercent: number;
}

/**
 * `lessonLock`'s internal shape is a large hand-edited JSON blob not
 * specified by the design doc -- round-tripped as-is, never decomposed.
 */
export interface PaywallConfig {
  schemaVersion: number;
  enableLessonLock: boolean;
  lessonLock?: Record<string, unknown>;
  autoOpen: PaywallAutoOpen;
  saleStrategy: PaywallSaleStrategy;
}

export interface PaywallConfigVersionUser {
  email?: string;
  name?: string;
}

export interface PaywallConfigVersion {
  versionNumber?: string;
  updateTime?: string;
  updateUser?: PaywallConfigVersionUser;
}

export interface PaywallConfigResponse {
  environment: PaywallEnvironment;
  config: PaywallConfig;
  // dev-only: "conditional" = a dev override exists; "default" = dev is
  // currently just inheriting the prod value. Always "default" for prod.
  source: "conditional" | "default";
  version?: PaywallConfigVersion;
}

/** Field-level validation error, as produced by PaywallConfigService. */
export interface PaywallConfigValidationError {
  field: string;
  message: string;
}
