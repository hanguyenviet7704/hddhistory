import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { Transform, Type } from 'class-transformer';
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
  Length,
  ValidateIf,
  ValidateNested,
} from 'class-validator';

import { CourseLevel } from 'src/modules/courses/src/modules/course/enum/course.enum';
import { DragDropOptionsDto } from 'src/modules/courses/src/modules/learning-item/dto/excercises/drag-drop.dto';
import { RecordAnswerDto } from 'src/modules/courses/src/modules/learning-item/dto/excercises/record.dto';
import { ExerciseSingleChoiceOptionDto } from 'src/modules/courses/src/modules/learning-item/dto/excercises/single-choice.dto';
import {
  ExerciseType,
  FormDragDropType,
} from 'src/modules/courses/src/modules/learning-item/enum/learning-item.enum';


export class UpdateLessonResultDto {
  @ApiProperty()
  @IsNotEmpty()
  @IsString()
  @Length(24)
  userId: string;

  @ApiProperty()
  @IsNotEmpty()
  @IsString()
  @Length(24)
  courseId: string;

  @ApiProperty()
  @IsNotEmpty()
  @IsNumber()
  averageScore: number;

  @ApiProperty({ type: Boolean })
  @IsNotEmpty()
  @IsBoolean()
  @Transform(({ value }) => value === true || value === 'true' || value === 1)
  passed: boolean;

  @ApiPropertyOptional()
  @IsOptional()
  @IsString()
  reviews: string;
}

class KeypointResultDto {
  @ApiProperty()
  @IsNotEmpty()
  @IsString()
  keypointId: string;

  @ApiProperty()
  @IsNotEmpty()
  @IsNumber()
  averageScore: number;

  @ApiProperty({ type: Boolean })
  @IsNotEmpty()
  @IsBoolean()
  @Transform(({ value }) => value === true || value === 'true' || value === 1)
  passed: boolean;

  @ApiPropertyOptional()
  @IsOptional()
  @IsString()
  reviews: string;
}

export class UpdateKeypointResultDto {
  @ApiProperty()
  @IsNotEmpty()
  @IsString()
  @Length(24)
  userId: string;

  @ApiProperty()
  @IsNotEmpty()
  @IsString()
  @Length(24)
  courseId: string;

  @ApiProperty()
  @IsNotEmpty()
  @IsString()
  lessonId: string;

  @IsArray()
  @ApiProperty({
    type: [KeypointResultDto],
    required: false,
    example: KeypointResultDto,
  })
  @ArrayNotEmpty()
  @Type(() => KeypointResultDto)
  @ValidateNested({ each: true })
  keypoints: KeypointResultDto[];
}

export class ExerciseResultDto {
  @ApiProperty()
  @IsNotEmpty()
  @IsString()
  exerciseId: string;

  @ApiProperty({
    enum: ExerciseType,
    example: ExerciseType.DRAG_DROP,
    required: true,
  })
  @IsNotEmpty()
  @IsEnum(ExerciseType)
  type: ExerciseType;

  @ApiProperty({
    enum: FormDragDropType,
    example: FormDragDropType.ArrangeTheSequence,
    required: true,
  })
  @IsOptional()
  @IsEnum(FormDragDropType)
  form: FormDragDropType;

  @ApiPropertyOptional({ type: Boolean })
  @IsOptional()
  @IsBoolean()
  @Transform(({ value }) => value === true || value === 'true' || value === 1)
  passed?: boolean;

  @ApiPropertyOptional()
  @IsOptional()
  @IsNumber()
  score: number;

  @IsArray()
  @ApiProperty({
    type: [ExerciseSingleChoiceOptionDto],
    required: false,
    example: ExerciseSingleChoiceOptionDto,
  })
  @IsOptional()
  @Type(() => ExerciseSingleChoiceOptionDto)
  @ValidateNested({ each: true })
  multipleAnswer: ExerciseSingleChoiceOptionDto[];

  @IsObject()
  @ApiPropertyOptional({
    type: ExerciseSingleChoiceOptionDto,
    example: ExerciseSingleChoiceOptionDto,
    required: false,
  })
  @IsOptional()
  @ValidateNested({ each: true })
  @Type(() => ExerciseSingleChoiceOptionDto)
  singleAnswer: ExerciseSingleChoiceOptionDto;

  @IsArray()
  @ApiProperty({
    type: [DragDropOptionsDto],
    required: false,
    example: DragDropOptionsDto,
  })
  @IsOptional()
  @Type(() => DragDropOptionsDto)
  @ValidateNested({ each: true })
  dragDropAnswer: DragDropOptionsDto[];

  @IsObject()
  @ApiPropertyOptional({
    type: RecordAnswerDto,
    example: RecordAnswerDto,
    required: false,
  })
  @IsOptional()
  @ValidateNested({ each: true })
  @Type(() => RecordAnswerDto)
  recordAnswer: RecordAnswerDto;
}

export class UpdateExerciseResultDto {
  @ApiProperty()
  @IsNotEmpty()
  @IsString()
  @Length(24)
  userId: string;

  @ApiProperty()
  @IsNotEmpty()
  @IsString()
  @Length(24)
  courseId: string;

  @ApiProperty()
  @IsNotEmpty()
  @IsString()
  lessonId: string;

  @ApiProperty()
  @IsNotEmpty()
  @IsString()
  keypointId: string;

  @IsArray()
  @ApiProperty({
    type: [ExerciseResultDto],
    required: false,
    example: ExerciseResultDto,
  })
  @ArrayNotEmpty()
  @Type(() => ExerciseResultDto)
  @ValidateNested({ each: true })
  exercises: ExerciseResultDto[];
}

export class UpdateCompletedLevelAdditionalContentRequestDto {
  @ApiProperty({
    description: 'User id that owns the course progress.',
    example: '65f2a4f6c1a3b9d8e7f6a5b4',
  })
  @IsNotEmpty()
  @IsString()
  @Length(24)
  userId: string;

  @ApiProperty({
    description: 'Course id that contains the completed level.',
    example: '65f2a4f6c1a3b9d8e7f6a5b5',
  })
  @IsNotEmpty()
  @IsString()
  @Length(24)
  courseId: string;

  @ApiProperty({
    description: 'Completed course level selected by the user.',
    enum: CourseLevel,
    example: CourseLevel.LEVEL1,
    required: true,
  })
  @IsNotEmpty()
  @IsEnum(CourseLevel)
  level: CourseLevel;

  @ApiProperty({
    type: Boolean,
    description: 'Whether user wants more content for the completed level.',
    example: true,
  })
  @IsNotEmpty()
  @IsBoolean()
  @Transform(({ value }) => value === true || value === 'true' || value === 1)
  requested: boolean;

  @ApiPropertyOptional({
    description: 'Optional text request from user. Accepts empty string.',
    example: '',
  })
  @ValidateIf((_, value) => value !== undefined)
  @IsString()
  @Transform(({ value }) =>
    typeof value === 'string' ? value.trim() : value,
  )
  requestText?: string;
}
