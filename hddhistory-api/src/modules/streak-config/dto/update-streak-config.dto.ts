import { ApiPropertyOptional } from '@nestjs/swagger';
import { Type } from 'class-transformer';
import { IsBoolean, IsInt, IsOptional, Max, Min } from 'class-validator';

export class UpdateStreakConfigDto {
  @ApiPropertyOptional({
    default: true,
    description: 'Kill switch. False hides the popup without an app release',
  })
  @IsOptional()
  @IsBoolean()
  popupEnabled?: boolean;

  @ApiPropertyOptional({
    example: 120,
    description:
      'Cumulative foreground seconds in the current day before the popup ' +
      'shows. Capped at 2 hours: past that nobody would ever see it, which ' +
      'looks identical to the feature being broken.',
  })
  @IsOptional()
  @Type(() => Number)
  @IsInt()
  @Min(0)
  @Max(7200)
  triggerAfterSeconds?: number;

  @ApiPropertyOptional({
    example: 3,
    description: 'Seconds before the toast dismisses itself. 0 = stay until tapped',
  })
  @IsOptional()
  @Type(() => Number)
  @IsInt()
  @Min(0)
  @Max(60)
  autoHideSeconds?: number;
}
