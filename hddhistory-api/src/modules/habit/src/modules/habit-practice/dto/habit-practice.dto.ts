import {
  ApiProperty,
  ApiPropertyOptional,
  OmitType,
  PartialType,
} from '@nestjs/swagger';
import {
  IsEnum,
  IsInt,
  IsMongoId,
  IsNotEmpty,
  IsOptional,
  Min,
} from 'class-validator';

import { HabitPracticeStatus } from '../enum/habit-practice.enum';

/** Point a habit at an authored `learning_item` (exercise, video or roleplay). */
export class CreateHabitPracticeDto {
  @ApiProperty({
    example: '6a66c6c96923bedc5b665635',
    description: 'Habit in the library this practice belongs to',
  })
  @IsNotEmpty()
  @IsMongoId()
  habitId: string;

  @ApiProperty({
    example: '6a2bb198654a04aa7f327a74',
    description:
      'The learning_item holding the content. Its `type` IS the practice method, which is why adding video/roleplay practices needs no schema change.',
  })
  @IsNotEmpty()
  @IsMongoId()
  learningItemId: string;

  @ApiPropertyOptional({ example: 0, default: 0, minimum: 0 })
  @IsOptional()
  @IsInt()
  @Min(0)
  order?: number;

  @ApiPropertyOptional({
    enum: HabitPracticeStatus,
    default: HabitPracticeStatus.DRAFT,
  })
  @IsOptional()
  @IsEnum(HabitPracticeStatus)
  status?: HabitPracticeStatus;
}

/**
 * `habitId` and `learningItemId` are omitted: the pair is what the row IS, and
 * a unique index enforces it. Repointing a practice means deleting the row and
 * creating the right one, which keeps the index honest.
 */
export class UpdateHabitPracticeDto extends PartialType(
  OmitType(CreateHabitPracticeDto, ['habitId', 'learningItemId'] as const),
) {}

export class GetListHabitPracticeDto {
  @ApiProperty({ example: '6a66c6c96923bedc5b665635' })
  @IsNotEmpty()
  @IsMongoId()
  habitId: string;
}
