import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { Type } from 'class-transformer';
import {
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

import { ExerciseDragDropDto } from './excercises/drag-drop.dto';
import { ExerciseMultipleChoiceDto } from './excercises/multiple-choice.dto';
import { ExerciseRecordDto } from './excercises/record.dto';
import { ExerciseSingleChoiceNoCorrectAnswerDto } from './excercises/single-choice-no-correct-answer.dto';
import { ExerciseSingleChoiceDto } from './excercises/single-choice.dto';
import { VideoQuestionDto } from './videos/video-question.dto';
import { LearningItemType } from '../enum/learning-item.enum';
import { RoleplayDto } from './roleplays/roleplay.dto';
import { TheoryDto } from './theories/theory.dto';

export class CreateLearningItemDto {
  @ApiProperty({
    type: Object,
    required: true,
    example: { en: 'Learning item Title', vi: 'Tiêu đề bài học' },
  })
  @IsObject()
  @IsNotEmptyObject()
  @IsMultiLangString()
  title: Record<string, string>;

  @ApiPropertyOptional({
    type: Object,
    required: false,
    example: { en: 'Learning item Description', vi: 'Mô tả bài học' },
  })
  @IsObject()
  @IsOptional()
  @IsMultiLangString()
  description: Record<string, string>;

  @ApiProperty({
    enum: LearningItemType,
    example: LearningItemType.EXERCISE,
    required: true,
  })
  @IsNotEmpty()
  @IsEnum(LearningItemType)
  type: LearningItemType;

  @ApiPropertyOptional({ required: false, example: 'https://example.com' })
  @IsString()
  @IsOptional()
  image: string;

  @ApiProperty({
    required: false,
    example: '68f8aac77777e0208a423161',
    description: 'id of keypoint',
  })
  @IsOptional()
  @IsString()
  keypointId: string;

  @IsArray()
  @ApiPropertyOptional({
    type: [ExerciseDragDropDto],
    example: ExerciseDragDropDto,
    required: false,
  })
  @Type(
    () =>
      ExerciseDragDropDto ||
      ExerciseSingleChoiceDto ||
      ExerciseMultipleChoiceDto ||
      ExerciseSingleChoiceNoCorrectAnswerDto ||
      ExerciseRecordDto,
  )
  @IsOptional()
  // @ValidateNested({ each: true })
  questions: (
    | ExerciseDragDropDto
    | ExerciseSingleChoiceDto
    | ExerciseMultipleChoiceDto
    | ExerciseSingleChoiceNoCorrectAnswerDto
    | ExerciseRecordDto
  )[];

  @IsArray()
  @ApiPropertyOptional({
    type: [ExerciseDragDropDto],
    example: ExerciseDragDropDto,
    required: false,
  })
  @Type(
    () =>
      ExerciseDragDropDto ||
      ExerciseSingleChoiceDto ||
      ExerciseMultipleChoiceDto ||
      ExerciseSingleChoiceNoCorrectAnswerDto ||
      ExerciseRecordDto,
  )
  @IsOptional()
  // @ValidateNested({ each: true })
  subQuestions: (
    | ExerciseDragDropDto
    | ExerciseSingleChoiceDto
    | ExerciseMultipleChoiceDto
    | ExerciseSingleChoiceNoCorrectAnswerDto
    | ExerciseRecordDto
  )[];

  @IsArray()
  @ApiPropertyOptional({
    type: [VideoQuestionDto],
    required: false,
    example: VideoQuestionDto,
  })
  @IsOptional()
  @Type(() => VideoQuestionDto)
  @ValidateNested({ each: true })
  videoQuestions?: VideoQuestionDto[];

  @IsArray()
  @ApiProperty({
    type: [TheoryDto],
    required: false,
    example: TheoryDto,
  })
  @IsOptional()
  @Type(() => TheoryDto)
  @ValidateNested({ each: true })
  documents: TheoryDto[];

  @IsObject()
  @ApiPropertyOptional({
    type: RoleplayDto,
    example: RoleplayDto,
    required: false,
  })
  @IsOptional()
  @ValidateNested({ each: true })
  @Type(() => RoleplayDto)
  roleplay: RoleplayDto;

  @IsArray()
  @ApiPropertyOptional({
    type: [String],
    example: ['tag1'],
    required: false,
  })
  @IsOptional()
  @IsString({ each: true })
  tag: string[];

  @ApiProperty({ type: Boolean, example: true, required: false })
  @IsOptional()
  @IsBoolean()
  isSub: boolean;

  @ApiProperty({ required: false, example: 1 })
  @IsOptional()
  @IsNumber()
  index: number;
}
