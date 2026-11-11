import { ApiPropertyOptional } from '@nestjs/swagger';
import { IsISO8601, IsOptional, IsString, MaxLength } from 'class-validator';

/** Days of history the readout shows when the caller names no window. */
const DEFAULT_WINDOW_DAYS = 30;

/**
 * Query for `GET /paywall-config/experiment/stats`.
 *
 * Dates are validated as ISO-8601 strings and parsed here rather than by a
 * `@Type(() => Date)` transform: an unparseable date silently becoming
 * `Invalid Date` would query a window of nothing and report it as "no results
 * yet", which is exactly the failure an experiment readout must not have.
 */
export class GetPaywallExperimentStatsDto {
  @ApiPropertyOptional({
    example: 'prod',
    description: 'Which app environment fired the events. Defaults to prod.',
  })
  @IsOptional()
  @IsString()
  @MaxLength(32)
  appEnv?: string;

  @ApiPropertyOptional({ example: '2026-08-01T00:00:00.000Z' })
  @IsOptional()
  @IsISO8601()
  from?: string;

  @ApiPropertyOptional({ example: '2026-08-31T23:59:59.999Z' })
  @IsOptional()
  @IsISO8601()
  to?: string;

  resolve(): { appEnv: string; from: Date; to: Date } {
    const to = this.to ? new Date(this.to) : new Date();
    const from = this.from
      ? new Date(this.from)
      : new Date(to.getTime() - DEFAULT_WINDOW_DAYS * 24 * 60 * 60 * 1000);

    return { appEnv: this.appEnv?.trim() || 'prod', from, to };
  }
}
