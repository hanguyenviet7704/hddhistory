import { ApiPropertyOptional } from '@nestjs/swagger';
import {
  IsArray,
  IsBoolean,
  IsOptional,
  IsString,
  Matches,
  ValidateIf,
} from 'class-validator';

import { REMINDER_TIME_REGEX } from '../interface/onboarding-answer.interface';

export class SaveOnboardingAnswerDto {
  @ApiPropertyOptional({ type: [String], example: ['LV', 'CX'] })
  @IsOptional()
  @IsArray()
  @IsString({ each: true })
  branchCodes?: string[];

  @ApiPropertyOptional({ type: [String], example: ['LV-1', 'CX-2'] })
  @IsOptional()
  @IsArray()
  @IsString({ each: true })
  packageCodes?: string[];

  @ApiPropertyOptional({ example: 'LV-1', nullable: true })
  @IsOptional()
  @ValidateIf(o => o.desireCode !== null)
  @IsString()
  desireCode?: string | null;

  @ApiPropertyOptional()
  @IsOptional()
  @IsBoolean()
  reminderEnabled?: boolean;

  @ApiPropertyOptional({ example: '21:00', nullable: true })
  @IsOptional()
  @ValidateIf(o => o.reminderTime !== null)
  @Matches(REMINDER_TIME_REGEX)
  reminderTime?: string | null;

  @ApiPropertyOptional({ nullable: true })
  @IsOptional()
  @ValidateIf(o => o.chosenCourseId !== null)
  @IsString()
  chosenCourseId?: string | null;

  @ApiPropertyOptional({ example: '25_34', nullable: true })
  @IsOptional()
  @ValidateIf(o => o.ageKey !== null)
  @IsString()
  ageKey?: string | null;

  @ApiPropertyOptional({ description: 'true khi user bấm xong màn kết quả' })
  @IsOptional()
  @IsBoolean()
  completed?: boolean;
}
