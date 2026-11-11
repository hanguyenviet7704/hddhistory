import { ITranslation } from '@utils/interface/common.interface';

export interface IOnboardingWelcomeDeckItem {
  key: string;
  label: ITranslation;
  imageUrl: string;
  order: number;
}

export interface IOnboardingWelcomeSection {
  titlePrefix: ITranslation;
  titleBrand: string;
  subtitle: ITranslation;
  ctaLabel: ITranslation;
  deck: IOnboardingWelcomeDeckItem[];
}

export interface IOnboardingNameSection {
  heading: ITranslation;
  headingHighlight: ITranslation;
  helper: ITranslation;
  inputHint: ITranslation;
  ctaLabel: ITranslation;
  iconUrl: string;
}

export interface IOnboardingAgeOption {
  key: string;
  label: ITranslation;
  order: number;
}

export interface IOnboardingAgeSection {
  headingTemplate: ITranslation;
  headingHighlight: ITranslation;
  ctaLabel: ITranslation;
  options: IOnboardingAgeOption[];
  iconUrl: string;
}

export interface IOnboardingPathSymptom {
  key: string;
  label: ITranslation;
  order: number;
}

export interface IOnboardingPathItem {
  key: string;
  label: ITranslation;
  iconKey: string;
  iconUrl: string;
  order: number;
  symptoms: IOnboardingPathSymptom[];
}

export interface IOnboardingPathsSection {
  heading: ITranslation;
  headingHighlight: ITranslation;
  helper: ITranslation;
  maxSelect: number;
  items: IOnboardingPathItem[];
}

export interface IOnboardingBrainSection {
  heading: ITranslation;
  headingHighlight: ITranslation;
  headingSuffix: ITranslation;
  unlockedPillTemplate: ITranslation;
  moreTemplate: ITranslation;
  imageUrl: string;
}

export interface IOnboardingHabitSection {
  heading: ITranslation;
  headingHighlight: ITranslation;
  subtitle: ITranslation;
  ctaLabel: ITranslation;
  iconUrl: string;
}

export interface IOnboardingNotifSection {
  heading: ITranslation;
  headingHighlight: ITranslation;
  subtitle: ITranslation;
  cardTitle: ITranslation;
  cardBody: ITranslation;
  cardTimestamp: ITranslation;
  ctaLabel: ITranslation;
  iconUrl: string;
}

export interface IOnboardingPickSection {
  heading: ITranslation;
  headingHighlight: ITranslation;
  eyebrow: ITranslation;
  label: ITranslation;
  primaryCta: ITranslation;
  secondaryCta: ITranslation;
  iconUrl: string;
}

export interface IOnboardingThemeSection {
  titlePrefix: ITranslation;
  titleHighlight: ITranslation;
  subtitle: ITranslation;
  ctaLabel: ITranslation;
  helper: ITranslation;
}

export interface IOnboardingDesireSection {
  heading: ITranslation;
  headingHighlight: ITranslation;
  helper: ITranslation;
}

export interface IOnboardingHowStep {
  title: ITranslation;
  body: ITranslation;
}

export interface IOnboardingHowSection {
  eyebrow: ITranslation;
  heading: ITranslation;
  headingHighlight: ITranslation;
  steps: IOnboardingHowStep[];
  footer: ITranslation;
  ctaLabel: ITranslation;
}

export interface IOnboardingReminderPreset {
  label: ITranslation;
  time: string;
}

export interface IOnboardingReminderSection {
  heading: ITranslation;
  headingHighlight: ITranslation;
  subtitle: ITranslation;
  timeSectionLabel: ITranslation;
  presets: IOnboardingReminderPreset[];
  ctaLabel: ITranslation;
  secondaryCtaLabel: ITranslation;
}

export interface IOnboardingLoadingSection {
  heading: ITranslation;
  headingHighlight: ITranslation;
  lines: ITranslation[];
}

export interface IOnboardingConfig {
  configKey: string;
  welcome: IOnboardingWelcomeSection;
  name: IOnboardingNameSection;
  age: IOnboardingAgeSection;
  paths: IOnboardingPathsSection;
  brain: IOnboardingBrainSection;
  habit: IOnboardingHabitSection;
  notif: IOnboardingNotifSection;
  pick: IOnboardingPickSection;
  theme: IOnboardingThemeSection;
  desire: IOnboardingDesireSection;
  how: IOnboardingHowSection;
  reminder: IOnboardingReminderSection;
  loading: IOnboardingLoadingSection;
  /** Show the FULL paywall right after onboarding completes. */
  showPaywallAfterOnboarding: boolean;
}
