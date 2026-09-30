import { ApiPropertyOptional } from '@nestjs/swagger';
import { IsEnum, IsOptional, IsString, Matches } from 'class-validator';

import { HabitPackLength, UserHabitState } from '../enum/user-habit.enum';

const REMINDER_TIME_REGEX = /^([01]\d|2[0-3]):([0-5]\d)$/;

export class UpdateUserHabitDto {
  @ApiPropertyOptional({
    enum: UserHabitState,
    description: 'active <-> draft to resume/pause; archived to soft-remove',
  })
  @IsOptional()
  @IsEnum(UserHabitState)
  state?: UserHabitState;

  @ApiPropertyOptional({ example: '07:00', description: 'Daily reminder time, HH:mm' })
  @IsOptional()
  @IsString()
  @Matches(REMINDER_TIME_REGEX, { message: 'reminderTime must be in HH:mm format' })
  reminderTime?: string;

  @ApiPropertyOptional({ enum: HabitPackLength })
  @IsOptional()
  @IsEnum(HabitPackLength)
  packLength?: HabitPackLength;
}
