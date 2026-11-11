import { ApiPropertyOptional } from '@nestjs/swagger';
import { IsInt, IsOptional, Max, Min } from 'class-validator';

export class UpdateHabitConfigDto {
  @ApiPropertyOptional({
    description:
      'Max simultaneously-active habits for non-premium users. Premium users are always unlimited.',
    example: 3,
    minimum: 1,
    maximum: 100,
  })
  @IsOptional()
  @IsInt()
  @Min(1)
  @Max(100)
  freeActiveSlots?: number;
}
