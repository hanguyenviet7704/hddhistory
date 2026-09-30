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

import { ExerciseType, FormDragDropType } from '../../enum/learning-item.enum';
import { DocumentDto } from '../document.dto';

class AnswerDto {
  @ApiProperty({ required: true, example: 1 })
  @IsNotEmpty()
  @IsNumber()
  id: number;

  @ApiProperty({
    type: Object,
    required: true,
    example: { en: 'Content correct options', vi: 'Nội dung câu hỏi' },
  })
  @IsObject()
  @IsNotEmptyObject()
  @IsMultiLangString()
  correctAnswer: Record<string, string>;
}

export class DragDropOptionsDto {
  @ApiProperty({ required: true, example: 1 })
  @IsNotEmpty()
  @IsNumber()
  id: number;

  @ApiProperty({
    type: Object,
    required: true,
    example: { en: 'Content of answer', vi: 'Nội dung câu trả lời' },
  })
  @IsObject()
  @IsNotEmptyObject()
  @IsMultiLangString()
  text: Record<string, string>;
}

export class ExerciseDragDropDto {
  @ApiProperty({ required: true, example: 1 })
  @IsNotEmpty()
  @IsNumber()
  id: number;

  @ApiPropertyOptional({
    required: false,
    example: 1,
    description: 'id of tag',
  })
  @IsOptional()
  @IsString()
  tagId: string;

  @ApiProperty({
    enum: ExerciseType,
    example: ExerciseType.DRAG_DROP,
    required: true,
  })
  @IsNotEmpty()
  @IsEnum(ExerciseType)
  type: ExerciseType = ExerciseType.DRAG_DROP;

  @ApiProperty({
    enum: FormDragDropType,
    example: FormDragDropType.ArrangeTheSequence,
    required: true,
  })
  @IsNotEmpty()
  @IsEnum(FormDragDropType)
  form: FormDragDropType;

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
    type: [AnswerDto],
    example: AnswerDto,
    required: false,
  })
  @ArrayNotEmpty()
  @ValidateNested({ each: true })
  answer: AnswerDto[];

  @IsArray()
  @ApiProperty({ type: [DragDropOptionsDto], example: DragDropOptionsDto, required: false })
  @ArrayNotEmpty()
  @ValidateNested({ each: true })
  options: DragDropOptionsDto[];

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
  @ApiProperty({
    enum: KeypointLevel,
    isArray: true,
    example: [KeypointLevel.MORE_PRACTICE, KeypointLevel.WEAK_POINT],
    required: false,
  })
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
