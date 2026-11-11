import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { Type } from 'class-transformer';
import {
  ArrayMinSize,
  IsArray,
  IsDefined,
  IsEnum,
  IsInt,
  IsNotEmpty,
  IsNotEmptyObject,
  IsObject,
  IsOptional,
  IsString,
  Min,
  ValidateNested,
} from 'class-validator';

import { IsMultiLangString } from '@utils/dto/multi-languge';

import { InAppSurveyClosedQuestionType } from '../enum/in-app-survey.enum';

export class InAppSurveyQuestionDto {
  @ApiProperty({
    type: Object,
    description: 'Localized question text.',
    example: { en: 'How do you feel about the app?', vi: 'Bạn thấy app thế nào?' },
  })
  @IsObject()
  @IsNotEmptyObject()
  @IsMultiLangString()
  question: Record<string, string>;

  @ApiPropertyOptional({
    type: Object,
    description: 'Localized helper text.',
    example: { en: 'Choose the closest answer.', vi: 'Chọn câu phù hợp nhất.' },
  })
  @IsOptional()
  @IsObject()
  @IsMultiLangString()
  guide?: Record<string, string>;
}

export class InAppSurveyEmojiDto {
  @ApiPropertyOptional({
    description: 'Human-readable emoji name.',
    example: 'happy',
  })
  @IsOptional()
  @IsString()
  name?: string;

  @ApiProperty({
    description: 'Dark-mode emoji image URL.',
    example: 'https://cdn.example.com/emojis/happy-dark.png',
  })
  @IsNotEmpty()
  @IsString()
  darkUrl: string;

  @ApiPropertyOptional({
    description: 'Light-mode emoji image URL.',
    example: 'https://cdn.example.com/emojis/happy-light.png',
  })
  @IsOptional()
  @IsString()
  lightUrl?: string;
}

export class InAppSurveyOptionDto {
  @ApiPropertyOptional({
    description: 'Stable option id. Backend generates one if omitted.',
    example: '7f8d4b1f-0f1f-4a70-8e50-97c4c53a1b11',
  })
  @IsOptional()
  @IsString()
  id?: string;

  @ApiProperty({
    description: 'Option icon image URL.',
    example: 'https://cdn.example.com/icons/bug.png',
  })
  @IsNotEmpty()
  @IsString()
  icon: string;

  @ApiProperty({
    type: Object,
    description: 'Localized option label.',
    example: { en: 'App is easy to use', vi: 'Ứng dụng dễ sử dụng' },
  })
  @IsObject()
  @IsNotEmptyObject()
  @IsMultiLangString()
  value: Record<string, string>;

}

export class InAppSurveyClosedQuestionDto extends InAppSurveyQuestionDto {
  @ApiPropertyOptional({
    enum: InAppSurveyClosedQuestionType,
    default: InAppSurveyClosedQuestionType.MULTIPLE_CHOICE,
    description: 'Selection mode for this closed question.',
    example: InAppSurveyClosedQuestionType.MULTIPLE_CHOICE,
  })
  @IsOptional()
  @IsEnum(InAppSurveyClosedQuestionType)
  type?: InAppSurveyClosedQuestionType;

  @ApiProperty({
    type: InAppSurveyOptionDto,
    isArray: true,
    description: 'Closed-question options.',
  })
  @IsArray()
  @ArrayMinSize(1)
  @ValidateNested({ each: true })
  @Type(() => InAppSurveyOptionDto)
  options: InAppSurveyOptionDto[];
}

export class InAppSurveyBranchDto {
  @ApiPropertyOptional({
    description: 'Stable branch id. Backend generates one if omitted.',
    example: 'c4c81fa2-0802-4f3b-bf6f-ff1aa02dc58e',
  })
  @IsOptional()
  @IsString()
  id?: string;

  @ApiProperty({
    type: InAppSurveyEmojiDto,
    description: 'Emoji shown as branch selector.',
  })
  @IsDefined()
  @ValidateNested()
  @Type(() => InAppSurveyEmojiDto)
  emoji: InAppSurveyEmojiDto;

  @ApiProperty({
    type: InAppSurveyClosedQuestionDto,
    description: 'Closed question shown after branch selection.',
  })
  @IsDefined()
  @ValidateNested()
  @Type(() => InAppSurveyClosedQuestionDto)
  closedQuestion: InAppSurveyClosedQuestionDto;

  @ApiProperty({
    type: InAppSurveyQuestionDto,
    description: 'Open question shown after closed question.',
  })
  @IsDefined()
  @ValidateNested()
  @Type(() => InAppSurveyQuestionDto)
  openQuestion: InAppSurveyQuestionDto;

  @ApiPropertyOptional({
    description: 'Display order. Backend normalizes this from array order.',
    example: 0,
  })
  @IsOptional()
  @IsInt()
  @Min(0)
  index?: number;

  @ApiPropertyOptional({
    description: 'Rating score for this branch. Defaults to array index + 1.',
    example: 1,
  })
  @IsOptional()
  @IsInt()
  @Min(1)
  score?: number;
}

export class UpsertInAppSurveyConfigDto {
  @ApiProperty({
    type: InAppSurveyQuestionDto,
    description: 'Initial guiding question before branch selection.',
  })
  @IsDefined()
  @ValidateNested()
  @Type(() => InAppSurveyQuestionDto)
  introQuestion: InAppSurveyQuestionDto;

  @ApiProperty({
    type: InAppSurveyBranchDto,
    isArray: true,
    description: 'Survey branches.',
  })
  @IsArray()
  @ArrayMinSize(1)
  @ValidateNested({ each: true })
  @Type(() => InAppSurveyBranchDto)
  branches: InAppSurveyBranchDto[];
}
