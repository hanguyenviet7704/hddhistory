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

export class ExerciseSingleChoiceNoCorrectAnswerOptionDto {
  @ApiProperty({
    type: Object,
    required: true,
    example: { en: 'Content of answer', vi: 'Nội dung câu trả lời' },
  })
  @IsObject()
  @IsNotEmptyObject()
  @IsMultiLangString()
  value: Record<string, string>;

  @ApiProperty({ required: true, example: 'group-a' })
  @IsNotEmpty()
  @IsString()
  documentGroupId: string;
}

export class ExerciseSingleChoiceNoCorrectAnswerDocumentGroupDto {
  @ApiProperty({ required: true, example: 'group-a' })
  @IsNotEmpty()
  @IsString()
  id: string;

  @IsArray()
  @ApiProperty({
    type: [DocumentDto],
    required: true,
    example: DocumentDto,
  })
  @ArrayNotEmpty()
  @Type(() => DocumentDto)
  @ValidateNested({ each: true })
  documents: DocumentDto[];
}

export class ExerciseSingleChoiceNoCorrectAnswerDto {
  @ApiProperty({ required: true, example: 1 })
  @IsNotEmpty()
  @IsNumber()
  id: number;

  @ApiPropertyOptional({ required: false, example: 'id of tag' })
  @IsOptional()
  @IsString()
  tagId: string;

  @ApiProperty({
    enum: ExerciseType,
    required: false,
    example: ExerciseType.SINGLE_CHOICE_NO_CORRECT_ANSWER,
  })
  @IsNotEmpty()
  @IsEnum(ExerciseType)
  type: ExerciseType = ExerciseType.SINGLE_CHOICE_NO_CORRECT_ANSWER;

  @IsArray()
  @ApiPropertyOptional({
    type: [DocumentDto],
    example: DocumentDto,
    required: false,
  })
  @Type(() => DocumentDto)
  @IsOptional()
  @ValidateNested({ each: true })
  document: DocumentDto[];

  @IsArray()
  @ApiProperty({
    type: [ExerciseSingleChoiceNoCorrectAnswerOptionDto],
    required: false,
    example: ExerciseSingleChoiceNoCorrectAnswerOptionDto,
  })
  @ArrayNotEmpty()
  @Type(() => ExerciseSingleChoiceNoCorrectAnswerOptionDto)
  @ValidateNested({ each: true })
  options: ExerciseSingleChoiceNoCorrectAnswerOptionDto[];

  @IsArray()
  @ApiProperty({
    type: [ExerciseSingleChoiceNoCorrectAnswerDocumentGroupDto],
    required: true,
    example: ExerciseSingleChoiceNoCorrectAnswerDocumentGroupDto,
  })
  @ArrayNotEmpty()
  @Type(() => ExerciseSingleChoiceNoCorrectAnswerDocumentGroupDto)
  @ValidateNested({ each: true })
  documentGroups: ExerciseSingleChoiceNoCorrectAnswerDocumentGroupDto[];

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
  @ApiProperty({ enum: KeypointLevel, isArray: true, example: KeypointLevel })
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
