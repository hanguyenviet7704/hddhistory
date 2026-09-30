import { ApiPropertyOptional } from '@nestjs/swagger';
import { IsOptional, IsString } from 'class-validator';

/**
 * Window for the habit check-in statistics.
 *
 * Unlike the lesson-feedback statistics, `habit_checkins` is genuine event data
 * — one row per habit per day (unique index `userHabitId + date`) — so these
 * numbers are counts of real check-ins, and a daily series is meaningful.
 *
 * `date` on a check-in is date-only at UTC midnight (see
 * `normalizeDateOnly`), so the window is compared against midnights too and no
 * end-of-day adjustment is needed.
 */
export class GetHabitCheckinStatisticsDto {
  @ApiPropertyOptional({ example: '2026-08-01', description: 'ISO date, inclusive' })
  @IsOptional()
  @IsString()
  startDate?: string;

  @ApiPropertyOptional({ example: '2026-08-31', description: 'ISO date, inclusive' })
  @IsOptional()
  @IsString()
  endDate?: string;
}
