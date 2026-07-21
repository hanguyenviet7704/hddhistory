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
  helper: OnboardingMultilang;
  inputHint: OnboardingMultilang;
  ctaLabel: OnboardingMultilang;
}

export interface OnboardingAgeOption {
  key: string;
  label: OnboardingMultilang;
  order: number;
}

export interface OnboardingAgeConfig {
  headingTemplate: OnboardingMultilang;
  ctaLabel: OnboardingMultilang;
  options: OnboardingAgeOption[];
}

export interface OnboardingPathItem {
  key: string;
  label: OnboardingMultilang;
  iconKey: string;
  iconUrl: string;
  order: number;
}

export interface OnboardingPathsConfig {
  heading: OnboardingMultilang;
  helper: OnboardingMultilang;
  maxSelect: number;
  items: OnboardingPathItem[];
}

export interface OnboardingBrainConfig {
  heading: OnboardingMultilang;
  unlockedPillTemplate: OnboardingMultilang;
  moreTemplate: OnboardingMultilang;
  // Optional hero image override — empty/absent means the app renders its
  // built-in default hexagon graphic instead.
  imageUrl?: string;
}

export interface OnboardingHabitConfig {
  heading: OnboardingMultilang;
  subtitle: OnboardingMultilang;
  ctaLabel: OnboardingMultilang;
}

export interface OnboardingNotifConfig {
  heading: OnboardingMultilang;
  subtitle: OnboardingMultilang;
  cardTitle: OnboardingMultilang;
  cardBody: OnboardingMultilang;
  cardTimestamp: OnboardingMultilang;
  ctaLabel: OnboardingMultilang;
}

export interface OnboardingPickConfig {
  heading: OnboardingMultilang;
  label: OnboardingMultilang;
  primaryCta: OnboardingMultilang;
  secondaryCta: OnboardingMultilang;
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
