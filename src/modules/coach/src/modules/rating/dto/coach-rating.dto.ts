import { ApiPropertyOptional } from '@nestjs/swagger';
import { IsBoolean, IsDateString, IsEnum, IsOptional } from 'class-validator';

import { ToBoolean } from '@utils/boolean.utils';

import { CoachRatingSource, CoachSessionKind } from '../enum/rating.enum';

export class GetCoachRatingsDto {
  @ApiPropertyOptional({
    type: Boolean,
    description:
      'The open queue (true), what has been handled (false), or everything when omitted. Unset is what the praise rows need: they never enter the queue, so a filter that defaults to it hides them for good.',
  })
  @IsOptional()
  @IsBoolean()
  @ToBoolean()
  needsReview?: boolean;

  @ApiPropertyOptional({ enum: CoachRatingSource })
  @IsOptional()
  @IsEnum(CoachRatingSource)
  source?: CoachRatingSource;

  @ApiPropertyOptional({
    enum: CoachSessionKind,
    description:
      'What the reader was doing when they closed. Rows written before 2026-09-14 carry none and match no value here.',
  })
  @IsOptional()
  @IsEnum(CoachSessionKind)
  sessionKind?: CoachSessionKind;

  @ApiPropertyOptional({ example: '2026-09-01', description: 'Inclusive lower bound on createdAt.' })
  @IsOptional()
  @IsDateString()
  from?: string;

  @ApiPropertyOptional({ example: '2026-09-14', description: 'Inclusive upper bound on createdAt.' })
  @IsOptional()
  @IsDateString()
  to?: string;
}
