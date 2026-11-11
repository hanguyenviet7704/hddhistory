import { ApiPropertyOptional } from '@nestjs/swagger';
import { Type } from 'class-transformer';
import {
  IsArray,
  IsBoolean,
  IsInt,
  IsNumber,
  IsObject,
  IsOptional,
  IsString,
  Matches,
  ValidateNested,
} from 'class-validator';

import { IsMultiLangString } from '@utils/dto/multi-languge';
// Cross-module import of a pure constant (no service/module coupling, and
// onboarding-answer never imports back from onboarding-config — checked
// before adding this), so the reminder-time format is defined in exactly one
// place instead of duplicated between the two modules that both validate it.
import { REMINDER_TIME_REGEX } from 'src/modules/onboarding-answer/interface/onboarding-answer.interface';

export class OnboardingWelcomeDeckItemDto {
  @ApiPropertyOptional({ example: 'card-1' })
  @IsOptional()
  @IsString()
  key?: string;

  @ApiPropertyOptional({
    type: Object,
    example: { en: 'Learn faster', vi: 'Học nhanh hơn' },
  })
  @IsOptional()
  @IsObject()
  @IsMultiLangString()
  label?: Record<string, string>;

  @ApiPropertyOptional({ example: 'https://cdn.meup.app/onboarding/card-1.png' })
  @IsOptional()
  @IsString()
  imageUrl?: string;

  @ApiPropertyOptional({ example: 1 })
  @IsOptional()
  @IsInt()
  order?: number;
}

export class OnboardingWelcomeSectionDto {
  @ApiPropertyOptional({ type: Object, example: { en: 'Welcome to', vi: 'Chào mừng đến với' } })
  @IsOptional()
  @IsObject()
  @IsMultiLangString()
  titlePrefix?: Record<string, string>;

  @ApiPropertyOptional({ example: 'HDDhistory' })
  @IsOptional()
  @IsString()
  titleBrand?: string;

  @ApiPropertyOptional({
    type: Object,
    example: { en: 'Your learning journey starts here', vi: 'Hành trình học tập của bạn bắt đầu tại đây' },
  })
  @IsOptional()
  @IsObject()
  @IsMultiLangString()
  subtitle?: Record<string, string>;

  @ApiPropertyOptional({ type: Object, example: { en: 'Get Started', vi: 'Bắt đầu' } })
  @IsOptional()
  @IsObject()
  @IsMultiLangString()
  ctaLabel?: Record<string, string>;

  @ApiPropertyOptional({ type: [OnboardingWelcomeDeckItemDto] })
  @IsOptional()
  @IsArray()
  @ValidateNested({ each: true })
  @Type(() => OnboardingWelcomeDeckItemDto)
  deck?: OnboardingWelcomeDeckItemDto[];
}

export class OnboardingNameSectionDto {
  @ApiPropertyOptional({ type: Object, example: { en: "What's your name?", vi: 'Tên của bạn là gì?' } })
  @IsOptional()
  @IsObject()
  @IsMultiLangString()
  heading?: Record<string, string>;

  @ApiPropertyOptional({ type: Object, example: { en: 'we call you?', vi: 'gọi bạn là gì?' } })
  @IsOptional()
  @IsObject()
  @IsMultiLangString()
  headingHighlight?: Record<string, string>;

  @ApiPropertyOptional({
    type: Object,
    example: { en: "We'll use this to personalize your journey", vi: 'Chúng tôi sẽ dùng tên này để cá nhân hóa hành trình của bạn' },
  })
  @IsOptional()
  @IsObject()
  @IsMultiLangString()
  helper?: Record<string, string>;

  @ApiPropertyOptional({ type: Object, example: { en: 'Enter your name', vi: 'Nhập tên của bạn' } })
  @IsOptional()
  @IsObject()
  @IsMultiLangString()
  inputHint?: Record<string, string>;

  @ApiPropertyOptional({ type: Object, example: { en: 'Continue', vi: 'Tiếp tục' } })
  @IsOptional()
  @IsObject()
  @IsMultiLangString()
  ctaLabel?: Record<string, string>;

  @ApiPropertyOptional({ example: 'https://cdn.meup.app/onboarding/name-icon.png' })
  @IsOptional()
  @IsString()
  iconUrl?: string;
}

export class OnboardingAgeOptionDto {
  @ApiPropertyOptional({ example: 'teen' })
  @IsOptional()
  @IsString()
  key?: string;

  @ApiPropertyOptional({ type: Object, example: { en: '13-17', vi: '13-17' } })
  @IsOptional()
  @IsObject()
  @IsMultiLangString()
  label?: Record<string, string>;

  @ApiPropertyOptional({ example: 1 })
  @IsOptional()
  @IsInt()
  order?: number;
}

export class OnboardingAgeSectionDto {
  @ApiPropertyOptional({
    type: Object,
    example: { en: 'Nice {name}, how old are you?', vi: '{name} ơi, bạn bao nhiêu tuổi?' },
  })
  @IsOptional()
  @IsObject()
  @IsMultiLangString()
  headingTemplate?: Record<string, string>;

  @ApiPropertyOptional({ type: Object, example: { en: 'how old are you?', vi: 'bạn bao nhiêu tuổi?' } })
  @IsOptional()
  @IsObject()
  @IsMultiLangString()
  headingHighlight?: Record<string, string>;

  @ApiPropertyOptional({ type: Object, example: { en: 'Continue', vi: 'Tiếp tục' } })
  @IsOptional()
  @IsObject()
  @IsMultiLangString()
  ctaLabel?: Record<string, string>;

  @ApiPropertyOptional({ type: [OnboardingAgeOptionDto] })
  @IsOptional()
  @IsArray()
  @ValidateNested({ each: true })
  @Type(() => OnboardingAgeOptionDto)
  options?: OnboardingAgeOptionDto[];

  @ApiPropertyOptional({ example: 'https://cdn.meup.app/onboarding/age-icon.png' })
  @IsOptional()
  @IsString()
  iconUrl?: string;
}

export class OnboardingPathSymptomDto {
  @ApiPropertyOptional({ example: 'motivation_disappears' })
  @IsOptional()
  @IsString()
  key?: string;

  @ApiPropertyOptional({
    type: Object,
    example: { en: 'Motivation disappears', vi: 'Động lực biến mất' },
  })
  @IsOptional()
  @IsObject()
  @IsMultiLangString()
  label?: Record<string, string>;

  @ApiPropertyOptional({ example: 1 })
  @IsOptional()
  @IsNumber()
  order?: number;
}

export class OnboardingPathItemDto {
  @ApiPropertyOptional({ example: 'feel_better' })
  @IsOptional()
  @IsString()
  key?: string;

  @ApiPropertyOptional({ type: Object, example: { en: 'Feel Better', vi: 'Cảm thấy tốt hơn' } })
  @IsOptional()
  @IsObject()
  @IsMultiLangString()
  label?: Record<string, string>;

  @ApiPropertyOptional({ example: 'cat-feel-better' })
  @IsOptional()
  @IsString()
  iconKey?: string;

  @ApiPropertyOptional({ example: 'https://cdn.meup.app/onboarding/cat-feel-better.svg' })
  @IsOptional()
  @IsString()
  iconUrl?: string;

  @ApiPropertyOptional({ example: 1 })
  @IsOptional()
  @IsInt()
  order?: number;

  @ApiPropertyOptional({ type: [OnboardingPathSymptomDto] })
  @IsOptional()
  @IsArray()
  @ValidateNested({ each: true })
  @Type(() => OnboardingPathSymptomDto)
  symptoms?: OnboardingPathSymptomDto[];
}

export class OnboardingPathsSectionDto {
  @ApiPropertyOptional({ type: Object, example: { en: 'Pick your paths', vi: 'Chọn lộ trình của bạn' } })
  @IsOptional()
  @IsObject()
  @IsMultiLangString()
  heading?: Record<string, string>;

  @ApiPropertyOptional({ type: Object, example: { en: 'your paths', vi: 'lộ trình của bạn' } })
  @IsOptional()
  @IsObject()
  @IsMultiLangString()
  headingHighlight?: Record<string, string>;

  @ApiPropertyOptional({
    type: Object,
    example: { en: 'Choose up to 2 paths', vi: 'Chọn tối đa 2 lộ trình' },
  })
  @IsOptional()
  @IsObject()
  @IsMultiLangString()
  helper?: Record<string, string>;

  @ApiPropertyOptional({ example: 2 })
  @IsOptional()
  @IsInt()
  maxSelect?: number;

  @ApiPropertyOptional({ type: [OnboardingPathItemDto] })
  @IsOptional()
  @IsArray()
  @ValidateNested({ each: true })
  @Type(() => OnboardingPathItemDto)
  items?: OnboardingPathItemDto[];
}

export class OnboardingBrainSectionDto {
  @ApiPropertyOptional({ type: Object, example: { en: 'Your brain on HDDhistory', vi: 'Bộ não của bạn với HDDhistory' } })
  @IsOptional()
  @IsObject()
  @IsMultiLangString()
  heading?: Record<string, string>;

  @ApiPropertyOptional({ type: Object, example: { en: 'on HDDhistory', vi: 'với HDDhistory' } })
  @IsOptional()
  @IsObject()
  @IsMultiLangString()
  headingHighlight?: Record<string, string>;

  @ApiPropertyOptional({ type: Object, example: { en: '', vi: '' } })
  @IsOptional()
  @IsObject()
  @IsMultiLangString()
  headingSuffix?: Record<string, string>;

  @ApiPropertyOptional({
    type: Object,
    example: { en: '{count} paths unlocked', vi: 'Đã mở khóa {count} lộ trình' },
  })
  @IsOptional()
  @IsObject()
  @IsMultiLangString()
  unlockedPillTemplate?: Record<string, string>;

  @ApiPropertyOptional({
    type: Object,
    example: { en: '{count} more waiting', vi: 'Còn {count} lộ trình đang chờ' },
  })
  @IsOptional()
  @IsObject()
  @IsMultiLangString()
  moreTemplate?: Record<string, string>;

  @ApiPropertyOptional({ example: 'https://cdn.meup.app/onboarding/brain.png' })
  @IsOptional()
  @IsString()
  imageUrl?: string;
}

export class OnboardingHabitSectionDto {
  @ApiPropertyOptional({ type: Object, example: { en: 'Build a habit', vi: 'Xây dựng thói quen' } })
  @IsOptional()
  @IsObject()
  @IsMultiLangString()
  heading?: Record<string, string>;

  @ApiPropertyOptional({ type: Object, example: { en: 'a habit', vi: 'thói quen' } })
  @IsOptional()
  @IsObject()
  @IsMultiLangString()
  headingHighlight?: Record<string, string>;

  @ApiPropertyOptional({
    type: Object,
    example: { en: 'A little every day goes a long way', vi: 'Mỗi ngày một chút sẽ tạo nên khác biệt lớn' },
  })
  @IsOptional()
  @IsObject()
  @IsMultiLangString()
  subtitle?: Record<string, string>;

  @ApiPropertyOptional({ type: Object, example: { en: 'Continue', vi: 'Tiếp tục' } })
  @IsOptional()
  @IsObject()
  @IsMultiLangString()
  ctaLabel?: Record<string, string>;

  @ApiPropertyOptional({ example: 'https://cdn.meup.app/onboarding/habit-icon.png' })
  @IsOptional()
  @IsString()
  iconUrl?: string;
}

export class OnboardingNotifSectionDto {
  @ApiPropertyOptional({ type: Object, example: { en: 'Stay on track', vi: 'Luôn đi đúng hướng' } })
  @IsOptional()
  @IsObject()
  @IsMultiLangString()
  heading?: Record<string, string>;

  @ApiPropertyOptional({ type: Object, example: { en: 'on track', vi: 'đúng hướng' } })
  @IsOptional()
  @IsObject()
  @IsMultiLangString()
  headingHighlight?: Record<string, string>;

  @ApiPropertyOptional({
    type: Object,
    example: { en: "We'll send gentle reminders", vi: 'Chúng tôi sẽ gửi lời nhắc nhẹ nhàng' },
  })
  @IsOptional()
  @IsObject()
  @IsMultiLangString()
  subtitle?: Record<string, string>;

  @ApiPropertyOptional({ type: Object, example: { en: 'HDDhistory', vi: 'HDDhistory' } })
  @IsOptional()
  @IsObject()
  @IsMultiLangString()
  cardTitle?: Record<string, string>;

  @ApiPropertyOptional({
    type: Object,
    example: { en: 'Time for your daily lesson!', vi: 'Đến giờ học bài rồi!' },
  })
  @IsOptional()
  @IsObject()
  @IsMultiLangString()
  cardBody?: Record<string, string>;

  @ApiPropertyOptional({ type: Object, example: { en: 'now', vi: 'bây giờ' } })
  @IsOptional()
  @IsObject()
  @IsMultiLangString()
  cardTimestamp?: Record<string, string>;

  @ApiPropertyOptional({ type: Object, example: { en: 'Turn on notifications', vi: 'Bật thông báo' } })
  @IsOptional()
  @IsObject()
  @IsMultiLangString()
  ctaLabel?: Record<string, string>;

  @ApiPropertyOptional({ example: 'https://cdn.meup.app/onboarding/notif-icon.png' })
  @IsOptional()
  @IsString()
  iconUrl?: string;
}

export class OnboardingPickSectionDto {
  @ApiPropertyOptional({ type: Object, example: { en: 'Pick your first course', vi: 'Chọn khóa học đầu tiên' } })
  @IsOptional()
  @IsObject()
  @IsMultiLangString()
  heading?: Record<string, string>;

  @ApiPropertyOptional({ type: Object, example: { en: 'first course', vi: 'khóa học đầu tiên' } })
  @IsOptional()
  @IsObject()
  @IsMultiLangString()
  headingHighlight?: Record<string, string>;

  @ApiPropertyOptional({ type: Object, example: { en: '', vi: '' } })
  @IsOptional()
  @IsObject()
  @IsMultiLangString()
  eyebrow?: Record<string, string>;

  @ApiPropertyOptional({
    type: Object,
    example: { en: 'Recommended for you', vi: 'Đề xuất cho bạn' },
  })
  @IsOptional()
  @IsObject()
  @IsMultiLangString()
  label?: Record<string, string>;

  @ApiPropertyOptional({ type: Object, example: { en: 'Start learning', vi: 'Bắt đầu học' } })
  @IsOptional()
  @IsObject()
  @IsMultiLangString()
  primaryCta?: Record<string, string>;

  @ApiPropertyOptional({ type: Object, example: { en: 'See all courses', vi: 'Xem tất cả khóa học' } })
  @IsOptional()
  @IsObject()
  @IsMultiLangString()
  secondaryCta?: Record<string, string>;

  @ApiPropertyOptional({ example: 'https://cdn.meup.app/onboarding/pick-icon.png' })
  @IsOptional()
  @IsString()
  iconUrl?: string;
}

export class OnboardingThemeSectionDto {
  @ApiPropertyOptional({ type: Object, example: { en: '', vi: '' } })
  @IsOptional()
  @IsObject()
  @IsMultiLangString()
  titlePrefix?: Record<string, string>;

  @ApiPropertyOptional({ type: Object, example: { en: '', vi: '' } })
  @IsOptional()
  @IsObject()
  @IsMultiLangString()
  titleHighlight?: Record<string, string>;

  @ApiPropertyOptional({ type: Object, example: { en: '', vi: '' } })
  @IsOptional()
  @IsObject()
  @IsMultiLangString()
  subtitle?: Record<string, string>;

  @ApiPropertyOptional({ type: Object, example: { en: '', vi: '' } })
  @IsOptional()
  @IsObject()
  @IsMultiLangString()
  ctaLabel?: Record<string, string>;

  @ApiPropertyOptional({ type: Object, example: { en: '', vi: '' } })
  @IsOptional()
  @IsObject()
  @IsMultiLangString()
  helper?: Record<string, string>;
}

export class OnboardingDesireSectionDto {
  @ApiPropertyOptional({
    type: Object,
    example: {
      en: 'If you could change just one thing in the next 10 days,',
      vi: 'Nếu chỉ được thay đổi một thứ trong 10 ngày tới,',
    },
  })
  @IsOptional()
  @IsObject()
  @IsMultiLangString()
  heading?: Record<string, string>;

  @ApiPropertyOptional({
    type: Object,
    example: { en: 'what would it be?', vi: 'bạn chọn gì?' },
  })
  @IsOptional()
  @IsObject()
  @IsMultiLangString()
  headingHighlight?: Record<string, string>;

  @ApiPropertyOptional({
    type: Object,
    example: {
      en: 'Pick the one that matters most.',
      vi: 'Chọn một điều quan trọng nhất với bạn.',
    },
  })
  @IsOptional()
  @IsObject()
  @IsMultiLangString()
  helper?: Record<string, string>;
}

export class OnboardingHowStepDto {
  @ApiPropertyOptional({
    type: Object,
    example: { en: 'Learn', vi: 'Hiểu' },
  })
  @IsOptional()
  @IsObject()
  @IsMultiLangString()
  title?: Record<string, string>;

  @ApiPropertyOptional({
    type: Object,
    example: {
      en: 'Bite-size lessons that fit your day',
      vi: 'Bài học siêu ngắn, vừa với lịch của bạn',
    },
  })
  @IsOptional()
  @IsObject()
  @IsMultiLangString()
  body?: Record<string, string>;
}

export class OnboardingHowSectionDto {
  @ApiPropertyOptional({
    type: Object,
    example: { en: 'How HDDhistory helps', vi: 'HDDhistory giúp bạn thế nào' },
  })
  @IsOptional()
  @IsObject()
  @IsMultiLangString()
  eyebrow?: Record<string, string>;

  @ApiPropertyOptional({
    type: Object,
    example: { en: 'Not just knowing', vi: 'Không dừng ở biết' },
  })
  @IsOptional()
  @IsObject()
  @IsMultiLangString()
  heading?: Record<string, string>;

  @ApiPropertyOptional({
    type: Object,
    example: {
      en: 'But putting it to use',
      vi: 'Mà phải ứng dụng được',
    },
  })
  @IsOptional()
  @IsObject()
  @IsMultiLangString()
  headingHighlight?: Record<string, string>;

  @ApiPropertyOptional({ type: [OnboardingHowStepDto] })
  @IsOptional()
  @IsArray()
  @ValidateNested({ each: true })
  @Type(() => OnboardingHowStepDto)
  steps?: OnboardingHowStepDto[];

  @ApiPropertyOptional({
    type: Object,
    example: {
      en: 'HDDhistory walks with you from the first lesson to the habit you keep.',
      vi: 'HDDhistory đi cùng bạn ở từng bước, từ bài học đầu tiên đến thói quen bạn giữ được mỗi ngày.',
    },
  })
  @IsOptional()
  @IsObject()
  @IsMultiLangString()
  footer?: Record<string, string>;

  @ApiPropertyOptional({
    type: Object,
    example: { en: "Let's go", vi: 'Bắt đầu thôi' },
  })
  @IsOptional()
  @IsObject()
  @IsMultiLangString()
  ctaLabel?: Record<string, string>;
}

export class OnboardingReminderPresetDto {
  @ApiPropertyOptional({
    type: Object,
    example: { en: 'Morning · 7:00', vi: 'Sáng · 7:00' },
  })
  @IsOptional()
  @IsObject()
  @IsMultiLangString()
  label?: Record<string, string>;

  @ApiPropertyOptional({ example: '07:00' })
  @IsOptional()
  @IsString()
  @Matches(REMINDER_TIME_REGEX)
  time?: string;
}

export class OnboardingReminderSectionDto {
  @ApiPropertyOptional({
    type: Object,
    example: {
      en: "The hard part isn't starting,",
      vi: 'Khó nhất không phải bắt đầu,',
    },
  })
  @IsOptional()
  @IsObject()
  @IsMultiLangString()
  heading?: Record<string, string>;

  @ApiPropertyOptional({
    type: Object,
    example: { en: "it's keeping going", vi: 'mà là duy trì' },
  })
  @IsOptional()
  @IsObject()
  @IsMultiLangString()
  headingHighlight?: Record<string, string>;

  @ApiPropertyOptional({
    type: Object,
    example: {
      en: 'A well-timed reminder keeps every day on track',
      vi: 'Lời nhắc đúng giờ giúp bạn không bỏ lỡ ngày nào',
    },
  })
  @IsOptional()
  @IsObject()
  @IsMultiLangString()
  subtitle?: Record<string, string>;

  @ApiPropertyOptional({
    type: Object,
    example: {
      en: 'PICK YOUR STUDY TIME',
      vi: 'CHỌN KHUNG GIỜ HỌC ƯA THÍCH',
    },
  })
  @IsOptional()
  @IsObject()
  @IsMultiLangString()
  timeSectionLabel?: Record<string, string>;

  @ApiPropertyOptional({ type: [OnboardingReminderPresetDto] })
  @IsOptional()
  @IsArray()
  @ValidateNested({ each: true })
  @Type(() => OnboardingReminderPresetDto)
  presets?: OnboardingReminderPresetDto[];

  @ApiPropertyOptional({
    type: Object,
    example: { en: 'Turn on notifications', vi: 'Bật thông báo' },
  })
  @IsOptional()
  @IsObject()
  @IsMultiLangString()
  ctaLabel?: Record<string, string>;

  @ApiPropertyOptional({
    type: Object,
    example: { en: 'Maybe later', vi: 'Để sau' },
  })
  @IsOptional()
  @IsObject()
  @IsMultiLangString()
  secondaryCtaLabel?: Record<string, string>;
}

export class OnboardingLoadingSectionDto {
  @ApiPropertyOptional({
    type: Object,
    example: { en: 'Picking a course', vi: 'Đề xuất khoá học' },
  })
  @IsOptional()
  @IsObject()
  @IsMultiLangString()
  heading?: Record<string, string>;

  @ApiPropertyOptional({
    type: Object,
    example: { en: 'for you', vi: 'dành cho bạn' },
  })
  @IsOptional()
  @IsObject()
  @IsMultiLangString()
  headingHighlight?: Record<string, string>;

  @ApiPropertyOptional({
    type: [Object],
    example: [{ en: 'What you care about', vi: 'Lĩnh vực bạn quan tâm' }],
  })
  @IsOptional()
  @IsArray()
  lines?: Record<string, string>[];
}

export class CreateOnboardingConfigDto {
  @ApiPropertyOptional({ type: OnboardingWelcomeSectionDto })
  @IsOptional()
  @IsObject()
  @ValidateNested()
  @Type(() => OnboardingWelcomeSectionDto)
  welcome?: OnboardingWelcomeSectionDto;

  @ApiPropertyOptional({ type: OnboardingNameSectionDto })
  @IsOptional()
  @IsObject()
  @ValidateNested()
  @Type(() => OnboardingNameSectionDto)
  name?: OnboardingNameSectionDto;

  @ApiPropertyOptional({ type: OnboardingAgeSectionDto })
  @IsOptional()
  @IsObject()
  @ValidateNested()
  @Type(() => OnboardingAgeSectionDto)
  age?: OnboardingAgeSectionDto;

  @ApiPropertyOptional({ type: OnboardingPathsSectionDto })
  @IsOptional()
  @IsObject()
  @ValidateNested()
  @Type(() => OnboardingPathsSectionDto)
  paths?: OnboardingPathsSectionDto;

  @ApiPropertyOptional({ type: OnboardingBrainSectionDto })
  @IsOptional()
  @IsObject()
  @ValidateNested()
  @Type(() => OnboardingBrainSectionDto)
  brain?: OnboardingBrainSectionDto;

  @ApiPropertyOptional({ type: OnboardingHabitSectionDto })
  @IsOptional()
  @IsObject()
  @ValidateNested()
  @Type(() => OnboardingHabitSectionDto)
  habit?: OnboardingHabitSectionDto;

  @ApiPropertyOptional({ type: OnboardingNotifSectionDto })
  @IsOptional()
  @IsObject()
  @ValidateNested()
  @Type(() => OnboardingNotifSectionDto)
  notif?: OnboardingNotifSectionDto;

  @ApiPropertyOptional({ type: OnboardingPickSectionDto })
  @IsOptional()
  @IsObject()
  @ValidateNested()
  @Type(() => OnboardingPickSectionDto)
  pick?: OnboardingPickSectionDto;

  @ApiPropertyOptional({ type: OnboardingThemeSectionDto })
  @IsOptional()
  @IsObject()
  @ValidateNested()
  @Type(() => OnboardingThemeSectionDto)
  theme?: OnboardingThemeSectionDto;

  @ApiPropertyOptional({ type: OnboardingDesireSectionDto })
  @IsOptional()
  @IsObject()
  @ValidateNested()
  @Type(() => OnboardingDesireSectionDto)
  desire?: OnboardingDesireSectionDto;

  @ApiPropertyOptional({ type: OnboardingHowSectionDto })
  @IsOptional()
  @IsObject()
  @ValidateNested()
  @Type(() => OnboardingHowSectionDto)
  how?: OnboardingHowSectionDto;

  @ApiPropertyOptional({ type: OnboardingReminderSectionDto })
  @IsOptional()
  @IsObject()
  @ValidateNested()
  @Type(() => OnboardingReminderSectionDto)
  reminder?: OnboardingReminderSectionDto;

  @ApiPropertyOptional({ type: OnboardingLoadingSectionDto })
  @IsOptional()
  @IsObject()
  @ValidateNested()
  @Type(() => OnboardingLoadingSectionDto)
  loading?: OnboardingLoadingSectionDto;

  @ApiPropertyOptional({
    type: Boolean,
    description: 'Show the FULL paywall right after onboarding completes.',
  })
  @IsOptional()
  @IsBoolean()
  showPaywallAfterOnboarding?: boolean;
}
