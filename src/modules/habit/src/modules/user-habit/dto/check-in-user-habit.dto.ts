import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import {
  IsBoolean,
  IsDateString,
  IsEnum,
  IsInt,
  IsOptional,
  IsString,
  Max,
  MaxLength,
  Min,
} from 'class-validator';

import { HabitCheckinMethod } from '../enum/user-habit.enum';

export class CheckInUserHabitDto {
  @ApiProperty({ example: true, description: '"Done" vs "Not yet" for the day' })
  @IsBoolean()
  done: boolean;

  @ApiPropertyOptional({
    example: '2026-07-05',
    description: 'Defaults to server today (UTC date) if omitted',
  })
  @IsOptional()
  @IsDateString()
  date?: string;

  @ApiPropertyOptional({
    example: 'Felt great sticking to this today!',
    description:
      "Optional diary note attached to this day's check-in. Also carries the free text of a journal practice.",
  })
  @IsOptional()
  @IsString()
  @MaxLength(1000)
  note?: string;

  @ApiPropertyOptional({
    enum: HabitCheckinMethod,
    example: HabitCheckinMethod.JOURNAL,
    description:
      'How the check-in was filed. Omit for the quick 7-day-strip toggle; it is then read as "tap".',
  })
  @IsOptional()
  @IsEnum(HabitCheckinMethod)
  method?: HabitCheckinMethod;

  @ApiPropertyOptional({
    example: 2,
    minimum: 1,
    maximum: 3,
    description:
      'Journal mood on a 3-level scale. 1-based on purpose — 0 is falsy in Dart and JS, which would silently drop the lowest level.',
  })
  @IsOptional()
  @IsInt()
  @Min(1)
  @Max(3)
  mood?: number;

  @ApiPropertyOptional({
    example: 3,
    minimum: 0,
    description:
      'Correct-answer count of a quiz practice. Per-question detail goes to habit_practice_attempts.',
  })
  @IsOptional()
  @IsInt()
  @Min(0)
  score?: number;
}
