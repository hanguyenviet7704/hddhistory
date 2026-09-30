import { ApiPropertyOptional } from '@nestjs/swagger';
import { Transform } from 'class-transformer';
import { IsBoolean, IsDateString, IsOptional, IsString } from 'class-validator';

import { DEFAULT_APP_ENV, DEFAULT_TIMEZONE } from '../constant/dashboard.constant';

/**
 * Shared query for every dashboard page.
 *
 * `from`/`to` are optional so a bare call still answers something useful (the
 * last 7 days) rather than 400-ing — the panel always sends them, but a
 * Swagger poke or a saved link with a stale query should not break.
 */
export class GetDashboardDto {
  @ApiPropertyOptional({ example: '2026-07-01T00:00:00.000Z' })
  @IsOptional()
  @IsDateString()
  from?: string;

  @ApiPropertyOptional({ example: '2026-08-09T23:59:59.999Z' })
  @IsOptional()
  @IsDateString()
  to?: string;

  @ApiPropertyOptional({
    default: DEFAULT_APP_ENV,
    description:
      'dev | stg | prod. Defaults to prod: our own dev traffic would ' +
      'otherwise be mixed into the product numbers.',
  })
  @IsOptional()
  @IsString()
  appEnv?: string = DEFAULT_APP_ENV;

  @ApiPropertyOptional({ example: 'ios', description: 'ios | android' })
  @IsOptional()
  @IsString()
  platform?: string;

  @ApiPropertyOptional({ example: '1.4.4' })
  @IsOptional()
  @IsString()
  appVersion?: string;

  @ApiPropertyOptional({
    default: DEFAULT_TIMEZONE,
    description: 'IANA zone used to bucket days and hours.',
  })
  @IsOptional()
  @IsString()
  timezone?: string = DEFAULT_TIMEZONE;

  @ApiPropertyOptional({
    default: true,
    description:
      'Also measure the preceding period of the same length, for the ' +
      'delta badges. Turn off to halve the query cost.',
  })
  @IsOptional()
  @Transform(({ value }) => value !== 'false' && value !== false)
  @IsBoolean()
  compare?: boolean = true;
}
