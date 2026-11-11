import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { Type } from 'class-transformer';
import {
  ArrayNotEmpty,
  IsArray,
  IsBoolean,
  IsEnum,
  IsNotEmpty,
  IsNotEmptyObject,
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

export class ExerciseSingleChoiceOptionDto {
  @ApiProperty({
    type: Object,
    required: true,
    example: { en: 'Content of answer', vi: 'Nội dung câu trả lời' },
  })
  @IsObject()
  @IsNotEmptyObject()
  @IsMultiLangString()
  value: Record<string, string>;

  @ApiProperty({ type: Boolean })
  @IsNotEmpty()
  @IsBoolean()
  isCorrect: boolean;
}

export class ExerciseSingleChoiceDto {
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
  type: ExerciseType = ExerciseType.SINGLE_CHOICE;

  @IsArray()
  @ApiPropertyOptional({
    type: [DocumentDto],
  })
  @Type(() => DocumentDto)
  @IsOptional()
  @ValidateNested({ each: true })
  document: DocumentDto[];

  @IsArray()
  @ApiProperty({
    type: [ExerciseSingleChoiceOptionDto],
    required: true,
  })
  @ArrayNotEmpty()
  @Type(() => ExerciseSingleChoiceOptionDto)
  @ValidateNested({ each: true })
  options: ExerciseSingleChoiceOptionDto[];

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
