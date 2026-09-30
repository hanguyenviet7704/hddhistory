import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { Type } from 'class-transformer';
import {
  IsArray,
  IsBoolean,
  IsDateString,
  IsEnum,
  IsInt,
  IsMongoId,
  IsNotEmpty,
  IsObject,
  IsOptional,
  IsString,
  Max,
  MaxLength,
  Min,
  ValidateNested,
} from 'class-validator';

import {
  ExerciseType,
  FormDragDropType,
} from 'src/modules/courses/src/modules/learning-item/enum/learning-item.enum';

import { HabitCheckinMethod } from '../../user-habit/enum/user-habit.enum';

/**
 * One question's outcome. Mirrors the `ExerciseResult` sub-schema that
 * user-progress already stores, so a habit quiz answer and a lesson exercise
 * answer have the same shape on disk.
 *
 * The identifying fields are validated; the answer payloads stay loose because
 * `ExerciseInput` is itself a union of five `Partial<...>` shapes and the
 * persisted column is `SchemaTypes.Mixed`/`Array`. Tightening them here would
 * only duplicate — and then drift from — the exercise DTOs.
 */
export class HabitPracticeExerciseResultDto {
  @ApiProperty({ example: '6a2bb198654a04aa7f327a74' })
  @IsNotEmpty()
  @IsString()
  exerciseId: string;

  @ApiPropertyOptional({ enum: ExerciseType })
  @IsOptional()
  @IsEnum(ExerciseType)
  type?: ExerciseType;

  @ApiPropertyOptional({ enum: FormDragDropType })
  @IsOptional()
  @IsEnum(FormDragDropType)
  form?: FormDragDropType;

  @ApiPropertyOptional({ example: true })
  @IsOptional()
  @IsBoolean()
  passed?: boolean;

  @ApiPropertyOptional({ example: 1, minimum: 0 })
  @IsOptional()
  @IsInt()
  @Min(0)
  score?: number;

  @ApiPropertyOptional({ type: [Object] })
  @IsOptional()
  @IsArray()
  multipleAnswer?: Record<string, any>[];

  @ApiPropertyOptional({ type: Object })
  @IsOptional()
  @IsObject()
  singleAnswer?: Record<string, any>;

  @ApiPropertyOptional({ type: [Object] })
  @IsOptional()
  @IsArray()
  dragDropAnswer?: Record<string, any>[];

  @ApiPropertyOptional({ type: Object })
  @IsOptional()
  @IsObject()
  recordAnswer?: Record<string, any>;
}

/**
 * Finish a practice. This also files the day's check-in: the picker that leads
 * here asks "How do you want to check in?", so a completed practice IS the
 * check-in — the client must not post to `/check-in` as well or the two writes
 * race on the same `{userHabitId, date}` row.
 */
export class SubmitHabitPracticeAttemptDto {
  @ApiProperty({
    example: '6a4b3329185ba0c31dfd5340',
    description: "The caller's adopted habit (user_habits._id)",
  })
  @IsNotEmpty()
  @IsMongoId()
  userHabitId: string;

  @ApiProperty({
    enum: HabitCheckinMethod,
    example: HabitCheckinMethod.EXERCISE,
    description:
      'Journal has no content; the other methods must match the learning item\'s type.',
  })
  @IsNotEmpty()
  @IsEnum(HabitCheckinMethod)
  method: HabitCheckinMethod;

  @ApiPropertyOptional({
    example: '6a2bb198654a04aa7f327a74',
    description: 'The practised learning item. Omit for a journal attempt.',
  })
  @IsOptional()
  @IsMongoId()
  learningItemId?: string;

  @ApiPropertyOptional({
    example: '2026-08-06',
    description:
      "The client's local calendar date. Omitted falls back to the user's timezone-resolved today, never the server's UTC date.",
  })
  @IsOptional()
  @IsDateString()
  date?: string;

  @ApiPropertyOptional({ type: [HabitPracticeExerciseResultDto] })
  @IsOptional()
  @IsArray()
  @ValidateNested({ each: true })
  @Type(() => HabitPracticeExerciseResultDto)
  exercisesResult?: HabitPracticeExerciseResultDto[];

  @ApiPropertyOptional({
    example: 3,
    minimum: 0,
    description:
      'Correct answers. Derived from exercisesResult when omitted, so the client cannot disagree with its own answers.',
  })
  @IsOptional()
  @IsInt()
  @Min(0)
  score?: number;

  @ApiPropertyOptional({ example: 4, minimum: 0 })
  @IsOptional()
  @IsInt()
  @Min(0)
  total?: number;

  @ApiPropertyOptional({
    example: 2,
    minimum: 1,
    maximum: 3,
    description: 'Journal mood, 1..3. 1-based because 0 is falsy in Dart and JS.',
  })
  @IsOptional()
  @IsInt()
  @Min(1)
  @Max(3)
  mood?: number;

  @ApiPropertyOptional({
    example: 'Managed to pause before replying today.',
    description: "Journal free text. Saved as the day's diary note.",
  })
  @IsOptional()
  @IsString()
  @MaxLength(1000)
  note?: string;
}
