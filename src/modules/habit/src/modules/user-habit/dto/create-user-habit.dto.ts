import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { IsEnum, IsMongoId, IsObject, IsOptional, IsString, Matches } from 'class-validator';

import { HabitPackLength } from '../enum/user-habit.enum';

const REMINDER_TIME_REGEX = /^([01]\d|2[0-3]):([0-5]\d)$/;

export class CreateUserHabitDto {
  @ApiProperty({ description: 'Library habit id to adopt' })
  @IsMongoId()
  habitId: string;

  @ApiPropertyOptional({ example: '07:00', description: 'Daily reminder time, HH:mm' })
  @IsOptional()
  @IsString()
  @Matches(REMINDER_TIME_REGEX, { message: 'reminderTime must be in HH:mm format' })
  reminderTime?: string;

  @ApiPropertyOptional({ enum: HabitPackLength, example: HabitPackLength.THREE_DAYS })
  @IsOptional()
  @IsEnum(HabitPackLength)
  packLength?: HabitPackLength;

  @ApiPropertyOptional({
    description: 'Keypoint this habit was suggested/adopted from',
  })
  @IsOptional()
  @IsMongoId()
  sourceKeypointId?: string;

  @ApiPropertyOptional({
    description: 'Course this habit was suggested/adopted from',
  })
  @IsOptional()
  @IsMongoId()
  sourceCourseId?: string;

  @ApiPropertyOptional({
    description: 'Re-anchor reason id the user picked for this course',
  })
  @IsOptional()
  @IsMongoId()
  reanchorReasonId?: string;

  @ApiPropertyOptional({
    type: Object,
    description: 'Picked re-anchor reason text (multilang snapshot) for grouping',
    example: { en: 'I want to stay curious', vi: 'Tôi muốn giữ sự tò mò' },
  })
  @IsOptional()
  @IsObject()
  reanchorReason?: Record<string, string>;
}
