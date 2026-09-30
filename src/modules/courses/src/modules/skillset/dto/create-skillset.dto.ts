import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import {
  IsEnum,
  IsNotEmptyObject,
  IsObject,
  IsOptional,
  IsString,
} from 'class-validator';

import { IsMultiLangString } from '@utils/dto/multi-languge';

import {
  SkillsetOnboardingIntroduce,
  SkillsetStatus,
} from '../enum/skillset.enum';

export class CreateSkillsetDto {
  @ApiProperty({
    type: Object,
    required: true,
    example: { en: 'Skillset title', vi: 'Tiêu đề Skillset' },
  })
  @IsObject()
  @IsNotEmptyObject()
  @IsMultiLangString()
  title: Record<string, string>;

  @ApiPropertyOptional({
    type: Object,
    required: false,
    example: { en: 'Skillset Description', vi: 'Mô tả Skillset' },
  })
  @IsObject()
  @IsOptional()
  @IsMultiLangString()
  description: Record<string, string>;

  @ApiPropertyOptional({
    required: false,
    example: 'https://example.com/image.jpg',
  })
  @IsString()
  @IsOptional()
  image: string;

  @ApiPropertyOptional({
    enum: SkillsetStatus,
    required: false,
    example: SkillsetStatus.PUBLISHED,
  })
  @IsOptional()
  @IsEnum(SkillsetStatus)
  status?: SkillsetStatus;

  @ApiPropertyOptional({
    enum: SkillsetOnboardingIntroduce,
    required: false,
    example: SkillsetOnboardingIntroduce.MY_FEELINGS_FEEL_LOUD,
    description:
      'Intro option shown in onboarding flow for the selected skillset.',
  })
  @IsOptional()
  @IsEnum(SkillsetOnboardingIntroduce)
  onboardingIntroduce?: SkillsetOnboardingIntroduce;
}
