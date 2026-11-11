import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import {
  IsEnum,
  IsNotEmpty,
  IsOptional,
  IsString,
  Length,
} from 'class-validator';

import { GradeResultType } from '../enum/user-progress.enum';

export class DeleteUserProgressDto {
  @ApiProperty({ required: true })
  @IsNotEmpty()
  @IsString()
  @Length(24)
  courseId: string;

  @ApiProperty({ required: true })
  @IsNotEmpty()
  @IsString()
  @Length(24)
  userId: string;

  @ApiProperty({ enum: GradeResultType })
  @IsNotEmpty()
  @IsEnum(GradeResultType)
  grade: GradeResultType;

  @ApiPropertyOptional()
  @IsOptional()
  @IsString()
  @Length(24)
  lessonId?: string;

  @ApiPropertyOptional()
  @IsOptional()
  @IsString()
  @Length(24)
  keypointId?: string;

  @ApiPropertyOptional()
  @IsOptional()
  @IsString()
  @Length(24)
  exerciseId?: string;
}
