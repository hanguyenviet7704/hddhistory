import { ApiPropertyOptional } from '@nestjs/swagger';
import { Type } from 'class-transformer';
import { IsInt, IsOptional, Max, Min } from 'class-validator';

/**
 * Minutes east of UTC, the same sign convention as
 * `-new Date().getTimezoneOffset()` — +420 for Hanoi, -300 for New York.
 *
 * The week boundary is the learner's Monday, so this is what decides which
 * seven days the recap is cut from. Absent means UTC, which is only right for a
 * caller with genuinely no timezone to declare.
 */
const TZ_OFFSET_MIN = -720;
const TZ_OFFSET_MAX = 840;

const ARCHIVE_TAKE_MAX = 50;

export class GetCurrentWeekRecapDto {
  @ApiPropertyOptional({ example: 420, minimum: TZ_OFFSET_MIN, maximum: TZ_OFFSET_MAX })
  @IsOptional()
  @Type(() => Number)
  @IsInt()
  @Min(TZ_OFFSET_MIN)
  @Max(TZ_OFFSET_MAX)
  tzOffset?: number;

  @ApiPropertyOptional({
    example: 1,
    minimum: 0,
    maximum: 1,
    default: 1,
    description:
      'Which week to read. 1 (default) is the finished week a recap is cut ' +
      'from. 0 is the week still in progress, returned as a PREVIEW: computed ' +
      'live, never stored, and never given a week number — so it always ' +
      'reflects what has been logged so far and cannot pollute the archive.',
  })
  @IsOptional()
  @Type(() => Number)
  @IsInt()
  @Min(0)
  @Max(1)
  weekOffset?: number = 1;
}

export class GetWeekRecapArchiveDto {
  @ApiPropertyOptional({ minimum: 1, default: 1 })
  @IsOptional()
  @Type(() => Number)
  @IsInt()
  @Min(1)
  page?: number = 1;

  @ApiPropertyOptional({ minimum: 1, maximum: ARCHIVE_TAKE_MAX, default: 20 })
  @IsOptional()
  @Type(() => Number)
  @IsInt()
  @Min(1)
  @Max(ARCHIVE_TAKE_MAX)
  take?: number = 20;
}
