import { ApiPropertyOptional } from '@nestjs/swagger';
import { IsEnum, IsOptional } from 'class-validator';

import { UserHabitState } from '../enum/user-habit.enum';

export class GetListUserHabitDto {
  @ApiPropertyOptional({ enum: UserHabitState })
  @IsOptional()
  @IsEnum(UserHabitState)
  state?: UserHabitState;
}
