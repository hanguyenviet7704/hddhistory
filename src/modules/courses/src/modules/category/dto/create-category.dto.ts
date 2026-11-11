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
  CategoryOnboardingIntroduce,
  CategoryStatus,
} from '../enum/category.enum';

export class CreateCategoryDto {
  @ApiProperty({
    type: Object,
    required: true,
    example: { en: 'Category title', vi: 'Tiêu đề chủ đề' },
  })
  @IsObject()
  @IsNotEmptyObject()
  @IsMultiLangString()
  title: Record<string, string>;

  @ApiPropertyOptional({
    type: Object,
    required: false,
    example: { en: 'Category Description', vi: 'Mô tả chủ đề' },
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
    enum: CategoryStatus,
    required: false,
    example: CategoryStatus.PUBLISHED,
  })
  @IsOptional()
  @IsEnum(CategoryStatus)
  status?: CategoryStatus;

  @ApiPropertyOptional({
    enum: CategoryOnboardingIntroduce,
    required: false,
    example: CategoryOnboardingIntroduce.MY_FEELINGS_FEEL_LOUD,
    description:
      'Intro option shown in onboarding flow for the selected category.',
  })
  @IsOptional()
  @IsEnum(CategoryOnboardingIntroduce)
  onboardingIntroduce?: CategoryOnboardingIntroduce;
}
