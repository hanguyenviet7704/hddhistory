import { ApiPropertyOptional, IntersectionType } from '@nestjs/swagger';
import { IsDateString, IsEnum, IsOptional } from 'class-validator';

import { PageOptionsDto } from '@utils/dto/paging/page.dto';

import { UserHabitState } from '../enum/user-habit.enum';

/**
 * Admin list of everyone with adopted habits. `search` (from [PageOptionsDto])
 * matches the user's email or name.
 */
export class GetAdminUserHabitsDto extends IntersectionType(PageOptionsDto) {
  @ApiPropertyOptional({
    enum: UserHabitState,
    description:
      'Only count habits in this state. Omit to include every state.',
  })
  @IsOptional()
  @IsEnum(UserHabitState)
  state?: UserHabitState;
}

/** One user's habits plus their full check-in log, optionally date-bounded. */
export class GetAdminUserHabitDetailDto {
  @ApiPropertyOptional({
    example: '2026-07-01',
    description: 'Inclusive lower bound on the check-in date (date-only)',
  })
  @IsOptional()
  @IsDateString()
  from?: string;

  @ApiPropertyOptional({
    example: '2026-07-31',
    description: 'Inclusive upper bound on the check-in date (date-only)',
  })
  @IsOptional()
  @IsDateString()
  to?: string;
}
