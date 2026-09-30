import { ApiPropertyOptional } from '@nestjs/swagger';
import { Type } from 'class-transformer';
import { IsInt, IsOptional, Max, Min } from 'class-validator';

/**
 * Minutes east of UTC, as the app reports its own offset. Bounds are the real
 * ones in use (UTC-12 .. UTC+14); absent means the caller declared no timezone
 * and the server's day is used, which is right for an older app build and for
 * the admin panel.
 */
const TZ_OFFSET_MIN = -720;
const TZ_OFFSET_MAX = 840;

/** Query for the two reader-facing room endpoints. */
export class GetReaderTopicsDto {
  @ApiPropertyOptional({
    example: 420,
    minimum: TZ_OFFSET_MIN,
    maximum: TZ_OFFSET_MAX,
    description: "Decides which day 'postsToday' counts.",
  })
  @IsOptional()
  @Type(() => Number)
  @IsInt()
  @Min(TZ_OFFSET_MIN)
  @Max(TZ_OFFSET_MAX)
  tzOffset?: number;
}
