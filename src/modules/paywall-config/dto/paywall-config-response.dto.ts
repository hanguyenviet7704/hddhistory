import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';

import { PaywallConfigDto } from './paywall-config.dto';

/**
 * Admin envelope for `GET`/`PUT /paywall-config` -- config plus the version
 * metadata MySQL now tracks natively (previously Remote Config's own
 * `template.version`). `GET /paywall-config/mobile` does NOT use this DTO --
 * it returns the raw `PaywallConfigDto` so the Flutter client's parser is
 * unaffected.
 */
export class PaywallConfigResponseDto {
  @ApiProperty({ type: PaywallConfigDto })
  config: PaywallConfigDto;

  @ApiProperty({ example: 3, description: 'Monotonically increasing, starts at 1.' })
  version: number;

  @ApiProperty({ example: '2026-07-27T09:00:00.000Z' })
  publishedAt: Date;

  @ApiPropertyOptional({
    example: 'admin@meup.training',
    description:
      "The publishing admin's user id/email, or the " +
      '"system:remote-config-seed" sentinel for the version-1 row created ' +
      'by the first-read Remote Config seed.',
  })
  publishedBy?: string;
}

/** One row of `GET /paywall-config/versions`. */
export class PaywallConfigVersionDto extends PaywallConfigResponseDto {
  @ApiProperty({
    example: true,
    description: 'Whether this is the version currently served live.',
  })
  isCurrent: boolean;
}
