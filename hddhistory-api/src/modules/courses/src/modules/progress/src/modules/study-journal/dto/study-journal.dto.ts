import { ApiPropertyOptional, ApiProperty } from '@nestjs/swagger';
import { Type } from 'class-transformer';
import { IsInt, IsOptional, Matches, Max, Min } from 'class-validator';

/**
 * Minutes east of UTC, the same sign convention as JavaScript's
 * `-new Date().getTimezoneOffset()` — +420 for Hanoi, -300 for New York.
 *
 * Bounds are the real-world extremes (UTC-12 … UTC+14). Absent means UTC:
 * "study day" is then the server's day, which is only right for a caller that
 * genuinely has no timezone to declare.
 */
const TZ_OFFSET_MIN = -720;
const TZ_OFFSET_MAX = 840;

export class GetStudyJournalDto {
  @ApiPropertyOptional({
    example: '2026-08',
    description: 'Month to read, `YYYY-MM`. Absent means the current month.',
  })
  @IsOptional()
  @Matches(/^\d{4}-(0[1-9]|1[0-2])$/, {
    message: 'month must be in YYYY-MM format',
  })
  month?: string;

  @ApiPropertyOptional({ example: 420, minimum: TZ_OFFSET_MIN, maximum: TZ_OFFSET_MAX })
  @IsOptional()
  @Type(() => Number)
  @IsInt()
  @Min(TZ_OFFSET_MIN)
  @Max(TZ_OFFSET_MAX)
  tzOffset?: number;
}

export class GetStudyJournalDayDto {
  @ApiProperty({ example: '2026-08-19', description: 'Local calendar day.' })
  @Matches(/^\d{4}-(0[1-9]|1[0-2])-(0[1-9]|[12]\d|3[01])$/, {
    message: 'date must be in YYYY-MM-DD format',
  })
  date: string;

  @ApiPropertyOptional({ example: 420, minimum: TZ_OFFSET_MIN, maximum: TZ_OFFSET_MAX })
  @IsOptional()
  @Type(() => Number)
  @IsInt()
  @Min(TZ_OFFSET_MIN)
  @Max(TZ_OFFSET_MAX)
  tzOffset?: number;
}
