// Admin-editable onboarding config — see meup-api/plans/260721-onboarding-redesign/plan.md (§5).
// The mobile app fetches this singleton once at onboarding start and renders
// each of its 9 screens (splash is static) from these fields.

// Every editable copy field is bilingual (en/vi) — the app falls back to
// English when Vietnamese is blank.
export interface OnboardingMultilang {
  en?: string;
  vi?: string;
}

export interface OnboardingWelcomeDeckItem {
  key: string;
  label: OnboardingMultilang;
  imageUrl: string;
  order: number;
}

export interface OnboardingWelcomeConfig {
  titlePrefix: OnboardingMultilang;
  titleBrand: string;
  subtitle: OnboardingMultilang;
  ctaLabel: OnboardingMultilang;
  deck: OnboardingWelcomeDeckItem[];
}

export interface OnboardingNameConfig {
  heading: OnboardingMultilang;
  // Gradient-highlighted trailing part of the title, rendered right after
  // `heading`, e.g. heading "What should" + headingHighlight "we call you?".
  headingHighlight?: OnboardingMultilang;
  helper: OnboardingMultilang;
  inputHint: OnboardingMultilang;
  ctaLabel: OnboardingMultilang;
  // Optional icon override — empty/absent means the app renders its
  // built-in default icon instead.
  iconUrl?: string;
}

export interface OnboardingAgeOption {
  key: string;
  label: OnboardingMultilang;
  order: number;
}

export interface OnboardingAgeConfig {
  headingTemplate: OnboardingMultilang;
  // Gradient-highlighted trailing part of the title, rendered right after
  // `headingTemplate`, mirroring OnboardingNameConfig.headingHighlight.
  headingHighlight?: OnboardingMultilang;
  ctaLabel: OnboardingMultilang;
  options: OnboardingAgeOption[];
  // Optional icon override — empty/absent means the app renders its
  // built-in default icon instead.
  iconUrl?: string;
}

// A symptom nested under a path item. `key` must equal one of the
// `OnboardingSymptom` enum values consumed by the mobile app (18 total, 3 per
// path) — see meup-api/plans/260721-onboard-v2-config-driven/contract.md.
// The admin edits it as free text (no fixed dropdown) so content managers can
// realign keys without a code change; validation only enforces non-empty +
// unique, mirroring path item keys.
export interface OnboardingPathSymptom {
  key: string;
  label: OnboardingMultilang;
  order: number;
}

export interface OnboardingPathItem {
  key: string;
  label: OnboardingMultilang;
  iconKey: string;
  iconUrl: string;
  order: number;
  symptoms: OnboardingPathSymptom[];
}

export interface OnboardingPathsConfig {
  heading: OnboardingMultilang;
  // Gradient-highlighted trailing part of the title, rendered right after
  // `heading`, mirroring OnboardingNameConfig.headingHighlight.
  headingHighlight?: OnboardingMultilang;
  helper: OnboardingMultilang;
  maxSelect: number;
  items: OnboardingPathItem[];
}

export interface OnboardingBrainConfig {
  heading: OnboardingMultilang;
  // Gradient-highlighted trailing part of the title, rendered right after
  // `heading`, mirroring OnboardingNameConfig.headingHighlight.
  headingHighlight?: OnboardingMultilang;
  unlockedPillTemplate: OnboardingMultilang;
  moreTemplate: OnboardingMultilang;
  // Optional hero image override — empty/absent means the app renders its
  // built-in default hexagon graphic instead.
  imageUrl?: string;
}

export interface OnboardingHabitConfig {
  heading: OnboardingMultilang;
  // Gradient-highlighted trailing part of the title, rendered right after
  // `heading`, mirroring OnboardingNameConfig.headingHighlight.
  headingHighlight?: OnboardingMultilang;
  subtitle: OnboardingMultilang;
  ctaLabel: OnboardingMultilang;
  // Optional icon override — empty/absent means the app renders its
  // built-in default icon instead.
  iconUrl?: string;
}

export interface OnboardingNotifConfig {
  heading: OnboardingMultilang;
  // Gradient-highlighted trailing part of the title, rendered right after
  // `heading`, mirroring OnboardingNameConfig.headingHighlight.
  headingHighlight?: OnboardingMultilang;
  subtitle: OnboardingMultilang;
  cardTitle: OnboardingMultilang;
  cardBody: OnboardingMultilang;
  cardTimestamp: OnboardingMultilang;
  ctaLabel: OnboardingMultilang;
  // Optional icon override — empty/absent means the app renders its
  // built-in default icon instead.
  iconUrl?: string;
}

export interface OnboardingPickConfig {
  heading: OnboardingMultilang;
  // Gradient-highlighted trailing part of the title, rendered right after
  // `heading`, mirroring OnboardingNameConfig.headingHighlight.
  headingHighlight?: OnboardingMultilang;
  label: OnboardingMultilang;
  primaryCta: OnboardingMultilang;
  secondaryCta: OnboardingMultilang;
  // Optional icon override — empty/absent means the app renders its
  // built-in default icon instead.
  iconUrl?: string;
}

// GET /onboarding-config → the singleton document. The API wraps every
// response as { statusCode, message, data }, so callers must read
// res.data.data (see onboardingConfigService) — never res.data at the
// wrapper level.
export interface OnboardingConfig {
  _id?: string;
  welcome: OnboardingWelcomeConfig;
  name: OnboardingNameConfig;
  age: OnboardingAgeConfig;
  paths: OnboardingPathsConfig;
  brain: OnboardingBrainConfig;
  habit: OnboardingHabitConfig;
  notif: OnboardingNotifConfig;
  pick: OnboardingPickConfig;
  createdAt?: string;
  updatedAt?: string;
}

// PUT /onboarding-config is a partial update; the admin editor always sends
// the whole content shape (minus bookkeeping fields) since it edits every
// screen on one page.
export type OnboardingConfigPayload = Partial<
  Omit<OnboardingConfig, "_id" | "createdAt" | "updatedAt">
>;
