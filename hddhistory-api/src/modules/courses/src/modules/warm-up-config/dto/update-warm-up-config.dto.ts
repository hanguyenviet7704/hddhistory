import { ApiPropertyOptional } from '@nestjs/swagger';
import { IsBoolean, IsEnum, IsInt, IsOptional, Min } from 'class-validator';

import { WarmUpInactivityUnit } from '../enum/warm-up-inactivity-unit.enum';

export class UpdateWarmUpConfigDto {
  @ApiPropertyOptional({
    description: 'Whether the lesson warm-up feature is enabled globally.',
    example: true,
  })
  @IsOptional()
  @IsBoolean()
  enabled?: boolean;

  @ApiPropertyOptional({
    description:
      'Amount of global inactivity before the "Let\'s warm up" lesson is offered, interpreted in the chosen unit.',
    example: 3,
    minimum: 1,
  })
  @IsOptional()
  @IsInt()
  @Min(1)
  inactivityValue?: number;

  @ApiPropertyOptional({
    description:
      'Unit for the inactivity threshold. Defaults to days; shorter units are intended for QA/testing.',
    enum: WarmUpInactivityUnit,
    example: WarmUpInactivityUnit.DAYS,
  })
  @IsOptional()
  @IsEnum(WarmUpInactivityUnit)
  inactivityUnit?: WarmUpInactivityUnit;
}
