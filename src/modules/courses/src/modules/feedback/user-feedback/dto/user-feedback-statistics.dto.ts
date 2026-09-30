import { ApiPropertyOptional } from '@nestjs/swagger';
import { Transform, Type } from 'class-transformer';
import { IsEnum, IsInt, IsOptional, IsString, Min } from 'class-validator';

import { FeedbackEntry, FeedbackType } from '../enum/user-feedback.enum';

/**
 * Shared filters for every learning-feedback statistics endpoint.
 *
 * The date window is matched against each embedded slot's own `submittedAt` —
 * the document has no top-level submission date (see the repository's
 * normalisation stage). Both bounds are optional: with neither, the endpoints
 * report over all time.
 */
export class GetUserFeedbackStatisticsDto {
  @ApiPropertyOptional({ example: '2026-08-01', description: 'ISO date, inclusive' })
  @IsOptional()
  @IsString()
  startDate?: string;

  @ApiPropertyOptional({ example: '2026-08-31', description: 'ISO date, inclusive' })
  @IsOptional()
  @IsString()
  endDate?: string;

  @ApiPropertyOptional({ enum: FeedbackEntry, description: 'keypoint | roleplay' })
  @IsOptional()
  @IsEnum(FeedbackEntry)
  entry?: FeedbackEntry;

  @ApiPropertyOptional({ enum: FeedbackType, description: 'complete | incomplete' })
  @IsOptional()
  @IsEnum(FeedbackType)
  type?: FeedbackType;
}

/** Paginated comment list — same filters plus paging. */
export class GetUserFeedbackCommentsDto extends GetUserFeedbackStatisticsDto {
  @ApiPropertyOptional({ example: 1 })
  @IsOptional()
  @Type(() => Number)
  @IsInt()
  @Min(1)
  page?: number;

  @ApiPropertyOptional({ example: 20 })
  @IsOptional()
  @Type(() => Number)
  @IsInt()
  @Min(1)
  @Transform(({ value }) => Math.min(Number(value) || 20, 100))
  take?: number;
}
