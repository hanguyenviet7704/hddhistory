import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { Type } from 'class-transformer';
import {
  ArrayNotEmpty,
  IsArray,
  IsBoolean,
  IsEnum,
  IsNotEmpty,
  IsNumber,
  IsObject,
  IsOptional,
  IsString,
  ValidateNested,
} from 'class-validator';

import { IsMultiLangString } from '@utils/dto/multi-languge';
import { KeypointLevel } from '@utils/enum/course.enum';

import { ExerciseType } from '../../enum/learning-item.enum';
import { DocumentDto } from '../document.dto';

export class ScoringCriteriaDto {
  @ApiProperty({ example: 10, required: true })
  @IsNotEmpty()
  @IsNumber()
  maxScore: number;

  @ApiProperty({ required: true, example: 'Correct pronunciation and fluency' })
  @IsNotEmpty()
  @IsString()
  tag: string;
}

export class RecordAnswerDto {
  @ApiProperty({ required: false, example: 'https://example.com' })
  @IsOptional()
  @IsString()
  record: string;

  @ApiProperty({ required: false, example: 'great...' })
  @IsOptional()
  @IsString()
  review: string;
}

export class ExerciseRecordDto {
  @ApiProperty()
  @IsNotEmpty()
  @IsNumber()
  id: number;

  @ApiPropertyOptional()
  @IsOptional()
  @IsString()
  tagId: string;

  @ApiProperty({ enum: ExerciseType })
  @IsNotEmpty()
  @IsEnum(ExerciseType)
  type: ExerciseType = ExerciseType.RECORD;

  @IsArray()
  @ApiPropertyOptional({
    type: [DocumentDto],
  })
  @Type(() => DocumentDto)
  @IsOptional()
  @ValidateNested({ each: true })
  document: DocumentDto[];

  @ApiPropertyOptional()
  @IsOptional()
  @IsString()
  record: string;

  @ApiPropertyOptional({
    type: Object,
    required: false,
    example: { en: 'Content of explanation', vi: 'Nội dung giải thích' },
  })
  @IsObject()
  @IsOptional()
  @IsMultiLangString()
  explanation: Record<string, string>;

  @IsArray()
  @ApiPropertyOptional({
    type: [ScoringCriteriaDto],
  })
  @Type(() => ScoringCriteriaDto)
  @IsOptional()
  @ValidateNested({ each: true })
  scoringCriteria: ScoringCriteriaDto[];

  @ApiPropertyOptional()
  @IsOptional()
  @IsNumber()
  maxDuration?: number;

  @ApiPropertyOptional()
  @IsOptional()
  @IsNumber()
  maxCharacter?: number;

  @IsArray()
  @ApiProperty({ enum: KeypointLevel, isArray: true })
  @ArrayNotEmpty()
  @IsEnum(KeypointLevel, { each: true })
  level: KeypointLevel[];

  @ApiProperty({ required: false, example: 1 })
  @IsOptional()
  @IsNumber()
  maxScore: number;

  @ApiPropertyOptional({
    required: false,
    example: false,
    description: 'Marks this question as eligible for Daily Warm-up.',
  })
  @IsOptional()
  @IsBoolean()
  isDailyWarmUp?: boolean;

  @ApiPropertyOptional({ required: false, example: '68f5fb2b4a6da8aa15a3fe8b' })
  @IsOptional()
  @IsString()
  keypointId: string;

  @ApiPropertyOptional({ required: false, example: 1 })
  @IsOptional()
  @IsNumber()
  mainQuestion: number;
}
