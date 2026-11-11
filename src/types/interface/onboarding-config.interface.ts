// Admin-editable onboarding config — see hddhistory-api/plans/260721-onboarding-redesign/plan.md (§5).
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
// path) — see hddhistory-api/plans/260721-onboard-v2-config-driven/contract.md.
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
  // Plain-text part of the title rendered after `headingHighlight` — used by
  // the shipped onboard_v2 path-map screen (screen 6) to close out the
  // heading, e.g. heading "Your" + headingHighlight "brain" + headingSuffix
  // "loves this.".
  headingSuffix: OnboardingMultilang;
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
  // Small label rendered above `heading` on the pick-course screen, e.g.
  // "STEP 3 OF 3" or "Almost there".
  eyebrow: OnboardingMultilang;
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

export interface OnboardingThemeConfig {
  titlePrefix: OnboardingMultilang;
  // Gradient-highlighted trailing part of the title, rendered right after
  // `titlePrefix`, mirroring OnboardingNameConfig.headingHighlight.
  titleHighlight: OnboardingMultilang;
  subtitle: OnboardingMultilang;
  ctaLabel: OnboardingMultilang;
  helper: OnboardingMultilang;
}

// Onboarding v3 (screen 6, "what do you want?") — see hddhistory-api plan-api Task 7.
export interface OnboardingDesireConfig {
  heading: OnboardingMultilang;
  // Gradient-highlighted trailing part of the title, rendered right after
  // `heading`, mirroring OnboardingNameConfig.headingHighlight.
  headingHighlight?: OnboardingMultilang;
  helper: OnboardingMultilang;
}

// Onboarding v3 (screen 7, "how HDDhistory teaches") — see hddhistory-api plan-api Task 7.
export interface OnboardingHowStep {
  title: OnboardingMultilang;
  body: OnboardingMultilang;
}

export interface OnboardingHowConfig {
  // Small label rendered above `heading`.
  eyebrow: OnboardingMultilang;
  heading: OnboardingMultilang;
  // Gradient-highlighted trailing part of the title, rendered right after
  // `heading`, mirroring OnboardingNameConfig.headingHighlight.
  headingHighlight?: OnboardingMultilang;
  steps: OnboardingHowStep[];
  footer: OnboardingMultilang;
  ctaLabel: OnboardingMultilang;
}

// Onboarding v3 (screen 8, "set a reminder") — see hddhistory-api plan-api Task 7.
export interface OnboardingReminderPreset {
  label: OnboardingMultilang;
  // 'HH:mm', e.g. "20:00".
  time: string;
}

export interface OnboardingReminderConfig {
  heading: OnboardingMultilang;
  // Gradient-highlighted trailing part of the title, rendered right after
  // `heading`, mirroring OnboardingNameConfig.headingHighlight.
  headingHighlight?: OnboardingMultilang;
  subtitle: OnboardingMultilang;
  timeSectionLabel: OnboardingMultilang;
  presets: OnboardingReminderPreset[];
  ctaLabel: OnboardingMultilang;
  secondaryCtaLabel: OnboardingMultilang;
}

// Onboarding v3 (screen 9, "building your roadmap" loading screen) — see
// hddhistory-api plan-api Task 7.
export interface OnboardingLoadingConfig {
  heading: OnboardingMultilang;
  // Gradient-highlighted trailing part of the title, rendered right after
  // `heading`, mirroring OnboardingNameConfig.headingHighlight.
  headingHighlight?: OnboardingMultilang;
  lines: OnboardingMultilang[];
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
  desire: OnboardingDesireConfig;
  how: OnboardingHowConfig;
  reminder: OnboardingReminderConfig;
  loading: OnboardingLoadingConfig;
  notif: OnboardingNotifConfig;
  pick: OnboardingPickConfig;
  theme: OnboardingThemeConfig;
  /** Show the FULL paywall right after onboarding completes. */
  showPaywallAfterOnboarding?: boolean;
  createdAt?: string;
  updatedAt?: string;
}

// PUT /onboarding-config is a partial update; the admin editor always sends
// the whole content shape (minus bookkeeping fields) since it edits every
// screen on one page.
export type OnboardingConfigPayload = Partial<
  Omit<OnboardingConfig, "_id" | "createdAt" | "updatedAt">
>;
