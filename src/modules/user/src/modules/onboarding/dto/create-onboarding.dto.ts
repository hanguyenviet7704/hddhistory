import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { Type } from 'class-transformer';
import {
  IsArray,
  IsNotEmpty,
  IsNotEmptyObject,
  IsNumber,
  IsObject,
  IsOptional,
  IsString,
  ValidateNested,
} from 'class-validator';

import { LabelDto } from '@utils/dto/common.dto';
import { IsMultiLangString } from '@utils/dto/multi-languge';

export class MotivationDto {
  @ApiPropertyOptional({ required: false, example: 'https://example.com' })
  @IsOptional()
  @IsString()
  image: string;

  @ApiPropertyOptional({
    type: Object,
    required: false,
    example: { en: 'Content introl title', vi: 'Nội dung intro onboarding' },
  })
  @IsObject()
  @IsOptional()
  @IsMultiLangString()
  content: Record<string, string>;
}

export class OnboardingIntroDto {
  @ApiPropertyOptional({ required: true, example: 1 })
  @IsNotEmpty()
  @IsNumber()
  id: number;

  @ApiProperty({
    type: Object,
    required: true,
    example: { en: 'Onboarding intro title', vi: 'Tiêu đề onboarding' },
  })
  @IsObject()
  @IsNotEmptyObject()
  @IsMultiLangString()
  title: Record<string, string>;

  @ApiPropertyOptional({ required: false, example: 'https://example.com' })
  @IsOptional()
  @IsString()
  image: string;

  @ApiPropertyOptional({
    type: Object,
    required: false,
    example: { en: 'Content introl title', vi: 'Nội dung intro onboarding' },
  })
  @IsObject()
  @IsOptional()
  @IsMultiLangString()
  content: Record<string, string>;

  @ApiPropertyOptional({ required: false, example: 'https://example.com' })
  @IsOptional()
  @IsString()
  source: string;

  @ApiPropertyOptional({ required: false, example: 'The Furture' })
  @IsOptional()
  @IsString()
  sourceTitle: string;
}

export class OnboardingSymptomDto {
  @ApiProperty({ required: true, example: 'MOTIVATION_DISAPPEARS' })
  @IsNotEmpty()
  @IsString()
  key: string;

  @ApiProperty({
    type: Object,
    required: true,
    example: { en: 'Motivation disappears', vi: 'Mất động lực' },
  })
  @IsObject()
  @IsNotEmptyObject()
  @IsMultiLangString()
  title: Record<string, string>;

  @ApiProperty({ required: true, example: 'MOTIVATION_DISAPPEARS' })
  @IsNotEmpty()
  @IsString()
  trackingLabel: string;

  @ApiProperty({ required: true, example: 1 })
  @IsNotEmpty()
  @IsNumber()
  order: number;
}

export class OnboardingPathDto {
  @ApiProperty({ required: true, example: 'FEEL_BETTER' })
  @IsNotEmpty()
  @IsString()
  key: string;

  @ApiProperty({
    type: Object,
    required: true,
    example: { en: 'Feel Better', vi: 'Cảm thấy tốt hơn' },
  })
  @IsObject()
  @IsNotEmptyObject()
  @IsMultiLangString()
  title: Record<string, string>;

  @ApiProperty({ required: true, example: 'Feel' })
  @IsNotEmpty()
  @IsString()
  shortTitle: string;

  @ApiProperty({ required: true, example: 'feel_better' })
  @IsNotEmpty()
  @IsString()
  iconKey: string;

  @ApiPropertyOptional({
    required: false,
    example: 'https://example.com/icon.png',
  })
  @IsOptional()
  @IsString()
  iconUrl?: string;

  @ApiProperty({ required: true, example: 'FEEL_BETTER' })
  @IsNotEmpty()
  @IsString()
  trackingLabel: string;

  @ApiProperty({ required: true, example: 1 })
  @IsNotEmpty()
  @IsNumber()
  order: number;

  @IsArray()
  @ApiProperty({
    type: [OnboardingSymptomDto],
    required: true,
  })
  @ValidateNested({ each: true })
  @Type(() => OnboardingSymptomDto)
  symptoms: OnboardingSymptomDto[];
}

export class OnboardingCopyDto {
  @ApiProperty({ required: true, example: 'WELCOME_TITLE' })
  @IsNotEmpty()
  @IsString()
  key: string;

  @ApiProperty({
    type: Object,
    required: true,
    example: { en: 'Welcome title', vi: 'Tiêu đề chào mừng' },
  })
  @IsObject()
  @IsMultiLangString()
  value: Record<string, string>;
}

export class CreateOnboardingDto {
  @IsArray()
  @IsOptional()
  @ValidateNested({ each: true })
  @Type(() => OnboardingIntroDto)
  @ApiPropertyOptional({
    type: [OnboardingIntroDto],
    example: OnboardingIntroDto,
    required: false,
  })
  intro?: OnboardingIntroDto[];

  @IsArray()
  @IsOptional()
  @ApiPropertyOptional({
    type: [LabelDto],
    example: [LabelDto],
    required: false,
  })
  @ValidateNested({ each: true })
  @Type(() => LabelDto)
  age: LabelDto[];

  @IsArray()
  @IsOptional()
  @ApiPropertyOptional({
    type: [LabelDto],
    example: LabelDto,
    required: false,
  })
  @ValidateNested({ each: true })
  @Type(() => LabelDto)
  gender: LabelDto[];

  @IsArray()
  @IsOptional()
  @ApiPropertyOptional({
    type: [LabelDto],
    example: LabelDto,
    required: false,
  })
  @ValidateNested({ each: true })
  @Type(() => LabelDto)
  skillsetWantToMaster: LabelDto[];

  @IsArray()
  @IsOptional()
  @ApiPropertyOptional({
    type: [LabelDto],
    example: LabelDto,
    required: false,
  })
  @ValidateNested({ each: true })
  @Type(() => LabelDto)
  learningGoal: LabelDto[];

  @IsArray()
  @IsOptional()
  @ApiPropertyOptional({
    type: [LabelDto],
    example: LabelDto,
    required: false,
  })
  @ValidateNested({ each: true })
  @Type(() => LabelDto)
  learningStruggles: LabelDto[];

  @IsArray()
  @IsOptional()
  @ApiPropertyOptional({
    type: [LabelDto],
    example: LabelDto,
    required: false,
  })
  @ValidateNested({ each: true })
  @Type(() => LabelDto)
  comfortableLearningTime: LabelDto[];

  @IsArray()
  @IsOptional()
  @ApiPropertyOptional({
    type: [LabelDto],
    example: LabelDto,
    required: false,
  })
  @ValidateNested({ each: true })
  @Type(() => LabelDto)
  dailyLearningGoal: LabelDto[];

  @IsObject()
  @IsOptional()
  @ApiPropertyOptional({
    type: MotivationDto,
    example: MotivationDto,
    required: false,
  })
  @ValidateNested({ each: true })
  @Type(() => MotivationDto)
  welcome: MotivationDto;

  @IsObject()
  @IsOptional()
  @ApiPropertyOptional({
    type: MotivationDto,
    example: MotivationDto,
    required: false,
  })
  @ValidateNested({ each: true })
  @Type(() => MotivationDto)
  motivationOne: MotivationDto;

  @IsObject()
  @IsOptional()
  @ApiPropertyOptional({
    type: MotivationDto,
    example: MotivationDto,
    required: false,
  })
  @ValidateNested({ each: true })
  @Type(() => MotivationDto)
  motivationTwo: MotivationDto;

  @IsObject()
  @IsOptional()
  @ApiPropertyOptional({
    type: MotivationDto,
    example: MotivationDto,
    required: false,
  })
  @ValidateNested({ each: true })
  @Type(() => MotivationDto)
  motivationThree: MotivationDto;

  @IsObject()
  @IsOptional()
  @ApiPropertyOptional({
    type: MotivationDto,
    example: MotivationDto,
    required: false,
  })
  @ValidateNested({ each: true })
  @Type(() => MotivationDto)
  loading: MotivationDto;

  @IsArray()
  @IsOptional()
  @ApiPropertyOptional({
    type: [OnboardingPathDto],
    example: OnboardingPathDto,
    required: false,
  })
  @ValidateNested({ each: true })
  @Type(() => OnboardingPathDto)
  paths?: OnboardingPathDto[];

  @IsArray()
  @IsOptional()
  @ApiPropertyOptional({
    type: [OnboardingCopyDto],
    example: OnboardingCopyDto,
    required: false,
  })
  @ValidateNested({ each: true })
  @Type(() => OnboardingCopyDto)
  copy?: OnboardingCopyDto[];
}
