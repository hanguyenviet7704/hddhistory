import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose';
import { SchemaTypes } from 'mongoose';

import { AbstractDocument } from '@base/database/mongodb/abstract.schema';

import {
  IOnboardingAgeSection,
  IOnboardingBrainSection,
  IOnboardingConfig,
  IOnboardingDesireSection,
  IOnboardingHabitSection,
  IOnboardingHowSection,
  IOnboardingLoadingSection,
  IOnboardingNameSection,
  IOnboardingNotifSection,
  IOnboardingPathsSection,
  IOnboardingPickSection,
  IOnboardingReminderSection,
  IOnboardingThemeSection,
  IOnboardingWelcomeSection,
} from '../interface/onboarding-config.interface';

// Singleton lookup key — there is only ever one OnboardingConfig document.
export const ONBOARDING_CONFIG_KEY = 'default';

export const DEFAULT_ONBOARDING_WELCOME_SECTION: IOnboardingWelcomeSection = {
  titlePrefix: {},
  titleBrand: '',
  subtitle: {},
  ctaLabel: {},
  deck: [],
};

export const DEFAULT_ONBOARDING_NAME_SECTION: IOnboardingNameSection = {
  heading: {},
  headingHighlight: {},
  helper: {},
  inputHint: {},
  ctaLabel: {},
  iconUrl: '',
};

export const DEFAULT_ONBOARDING_AGE_SECTION: IOnboardingAgeSection = {
  headingTemplate: {},
  headingHighlight: {},
  ctaLabel: {},
  options: [],
  iconUrl: '',
};

export const DEFAULT_ONBOARDING_PATHS_SECTION: IOnboardingPathsSection = {
  heading: {},
  headingHighlight: {},
  helper: {},
  maxSelect: 2,
  items: [],
};

export const DEFAULT_ONBOARDING_BRAIN_SECTION: IOnboardingBrainSection = {
  heading: {},
  headingHighlight: {},
  headingSuffix: {},
  unlockedPillTemplate: {},
  moreTemplate: {},
  imageUrl: '',
};

export const DEFAULT_ONBOARDING_HABIT_SECTION: IOnboardingHabitSection = {
  heading: {},
  headingHighlight: {},
  subtitle: {},
  ctaLabel: {},
  iconUrl: '',
};

export const DEFAULT_ONBOARDING_NOTIF_SECTION: IOnboardingNotifSection = {
  heading: {},
  headingHighlight: {},
  subtitle: {},
  cardTitle: {},
  cardBody: {},
  cardTimestamp: {},
  ctaLabel: {},
  iconUrl: '',
};

export const DEFAULT_ONBOARDING_PICK_SECTION: IOnboardingPickSection = {
  heading: {},
  headingHighlight: {},
  eyebrow: {},
  label: {},
  primaryCta: {},
  secondaryCta: {},
  iconUrl: '',
};

export const DEFAULT_ONBOARDING_THEME_SECTION: IOnboardingThemeSection = {
  titlePrefix: {},
  titleHighlight: {},
  subtitle: {},
  ctaLabel: {},
  helper: {},
};

export const DEFAULT_ONBOARDING_DESIRE_SECTION: IOnboardingDesireSection = {
  heading: {
    vi: 'Nếu chỉ được thay đổi một thứ trong 10 ngày tới,',
    en: 'If you could change just one thing in the next 10 days,',
  },
  headingHighlight: { vi: 'bạn chọn gì?', en: 'what would it be?' },
  helper: {
    vi: 'Chọn một điều quan trọng nhất với bạn.',
    en: 'Pick the one that matters most.',
  },
};

export const DEFAULT_ONBOARDING_HOW_SECTION: IOnboardingHowSection = {
  eyebrow: { vi: 'HDDhistory giúp bạn thế nào', en: 'How HDDhistory helps' },
  heading: { vi: 'Không dừng ở biết', en: 'Not just knowing' },
  headingHighlight: {
    vi: 'Mà phải ứng dụng được',
    en: 'But putting it to use',
  },
  steps: [
    {
      title: { vi: 'Hiểu', en: 'Learn' },
      body: {
        vi: 'Bài học siêu ngắn, vừa với lịch của bạn',
        en: 'Bite-size lessons that fit your day',
      },
    },
    {
      title: { vi: 'Thử', en: 'Try' },
      body: {
        vi: 'Luyện tập cùng AI ngay sau khi học',
        en: 'Practice with AI right after',
      },
    },
    {
      title: { vi: 'Ôn', en: 'Review' },
      body: {
        vi: 'HDDhistory nhắc lại trước khi bạn kịp quên',
        en: 'HDDhistory reminds you before you forget',
      },
    },
    {
      title: { vi: 'Dùng', en: 'Apply' },
      body: {
        vi: 'Hướng dẫn mang bài học vào việc thật mỗi ngày',
        en: 'Guidance to use it in real life every day',
      },
    },
  ],
  footer: {
    vi: 'HDDhistory đi cùng bạn ở từng bước, từ bài học đầu tiên đến thói quen bạn giữ được mỗi ngày.',
    en: 'HDDhistory walks with you from the first lesson to the habit you keep.',
  },
  ctaLabel: { vi: 'Bắt đầu thôi', en: "Let's go" },
};

export const DEFAULT_ONBOARDING_REMINDER_SECTION: IOnboardingReminderSection =
  {
    heading: {
      vi: 'Khó nhất không phải bắt đầu,',
      en: "The hard part isn't starting,",
    },
    headingHighlight: { vi: 'mà là duy trì', en: "it's keeping going" },
    subtitle: {
      vi: 'Lời nhắc đúng giờ giúp bạn không bỏ lỡ ngày nào',
      en: 'A well-timed reminder keeps every day on track',
    },
    timeSectionLabel: {
      vi: 'CHỌN KHUNG GIỜ HỌC ƯA THÍCH',
      en: 'PICK YOUR STUDY TIME',
    },
    presets: [
      { label: { vi: 'Sáng · 7:00', en: 'Morning · 7:00' }, time: '07:00' },
      { label: { vi: 'Trưa · 12:30', en: 'Noon · 12:30' }, time: '12:30' },
      { label: { vi: 'Tối · 21:00', en: 'Evening · 21:00' }, time: '21:00' },
    ],
    ctaLabel: { vi: 'Bật thông báo', en: 'Turn on notifications' },
    secondaryCtaLabel: { vi: 'Để sau', en: 'Maybe later' },
  };

export const DEFAULT_ONBOARDING_LOADING_SECTION: IOnboardingLoadingSection = {
  heading: { vi: 'Đề xuất khoá học', en: 'Picking a course' },
  headingHighlight: { vi: 'dành cho bạn', en: 'for you' },
  lines: [
    { vi: 'Lĩnh vực bạn quan tâm', en: 'What you care about' },
    { vi: 'Điều bạn đang vướng', en: "What's in your way" },
    { vi: 'Điều bạn muốn thay đổi', en: 'What you want to change' },
    { vi: 'Khung giờ học ưa thích', en: 'Your study time' },
  ],
};

@Schema({ collection: 'onboarding_configs' })
export class OnboardingConfig
  extends AbstractDocument
  implements IOnboardingConfig
{
  @Prop({ required: true, default: ONBOARDING_CONFIG_KEY })
  configKey: string;

  @Prop({
    type: SchemaTypes.Mixed,
    default: () => DEFAULT_ONBOARDING_WELCOME_SECTION,
  })
  welcome: IOnboardingWelcomeSection;

  @Prop({
    type: SchemaTypes.Mixed,
    default: () => DEFAULT_ONBOARDING_NAME_SECTION,
  })
  name: IOnboardingNameSection;

  @Prop({
    type: SchemaTypes.Mixed,
    default: () => DEFAULT_ONBOARDING_AGE_SECTION,
  })
  age: IOnboardingAgeSection;

  @Prop({
    type: SchemaTypes.Mixed,
    default: () => DEFAULT_ONBOARDING_PATHS_SECTION,
  })
  paths: IOnboardingPathsSection;

  @Prop({
    type: SchemaTypes.Mixed,
    default: () => DEFAULT_ONBOARDING_BRAIN_SECTION,
  })
  brain: IOnboardingBrainSection;

  @Prop({
    type: SchemaTypes.Mixed,
    default: () => DEFAULT_ONBOARDING_HABIT_SECTION,
  })
  habit: IOnboardingHabitSection;

  @Prop({
    type: SchemaTypes.Mixed,
    default: () => DEFAULT_ONBOARDING_NOTIF_SECTION,
  })
  notif: IOnboardingNotifSection;

  @Prop({
    type: SchemaTypes.Mixed,
    default: () => DEFAULT_ONBOARDING_PICK_SECTION,
  })
  pick: IOnboardingPickSection;

  @Prop({
    type: SchemaTypes.Mixed,
    default: () => DEFAULT_ONBOARDING_THEME_SECTION,
  })
  theme: IOnboardingThemeSection;

  @Prop({
    type: SchemaTypes.Mixed,
    default: () => DEFAULT_ONBOARDING_DESIRE_SECTION,
  })
  desire: IOnboardingDesireSection;

  @Prop({
    type: SchemaTypes.Mixed,
    default: () => DEFAULT_ONBOARDING_HOW_SECTION,
  })
  how: IOnboardingHowSection;

  @Prop({
    type: SchemaTypes.Mixed,
    default: () => DEFAULT_ONBOARDING_REMINDER_SECTION,
  })
  reminder: IOnboardingReminderSection;

  @Prop({
    type: SchemaTypes.Mixed,
    default: () => DEFAULT_ONBOARDING_LOADING_SECTION,
  })
  loading: IOnboardingLoadingSection;

  // Show the FULL paywall right after onboarding completes (admin toggle on
  // the Onboarding Config page). Off by default: surfacing a price screen to
  // a brand-new user is a product decision, never an accident of deploy.
  @Prop({ type: Boolean, default: false })
  showPaywallAfterOnboarding: boolean;
}

export const OnboardingConfigSchema =
  SchemaFactory.createForClass(OnboardingConfig);

// Enforces the singleton invariant at the DB level.
OnboardingConfigSchema.index({ configKey: 1 }, { unique: true });
