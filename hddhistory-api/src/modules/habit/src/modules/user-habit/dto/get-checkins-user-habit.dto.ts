import { ApiPropertyOptional } from '@nestjs/swagger';
import { IsDateString, IsOptional } from 'class-validator';

export class GetCheckinsUserHabitDto {
  @ApiPropertyOptional({
    example: '2026-07-01',
    description: 'Inclusive lower bound (ISO date). Omit for no lower bound.',
  })
  @IsOptional()
  @IsDateString()
  from?: string;

  @ApiPropertyOptional({
    example: '2026-07-31',
    description: 'Inclusive upper bound (ISO date). Omit for no upper bound.',
  })
  @IsOptional()
  @IsDateString()
  to?: string;
}
