import { ApiPropertyOptional } from '@nestjs/swagger';
import { IsOptional, IsString, Matches } from 'class-validator';

export class GetCoachMetricsDto {
  @ApiPropertyOptional({
    example: '2026-W36',
    description:
      'ISO week, `YYYY-Www`. Omit for the most recent week that has data — ' +
      'the panel opens on it rather than on an empty current week.',
  })
  @IsOptional()
  @IsString()
  @Matches(/^\d{4}-W\d{2}$/, { message: 'isoWeek must look like 2026-W36' })
  isoWeek?: string;
}
