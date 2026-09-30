import {
  ApiProperty,
  ApiPropertyOptional,
  IntersectionType,
} from '@nestjs/swagger';
import { Type } from 'class-transformer';
import {
  IsBoolean,
  IsEnum,
  IsNotEmpty,
  IsNumber,
  IsOptional,
  IsString,
  Length,
  Max,
  Min,
} from 'class-validator';

import { ToBoolean } from '@utils/boolean.utils';
import { PageOptionsDto } from '@utils/dto/paging/page.dto';

import { GradeResultType } from '../enum/user-progress.enum';

export class GetUserProgressDto extends IntersectionType(PageOptionsDto) {
  @ApiProperty()
  @IsNotEmpty()
  @IsString()
  @Length(24)
  courseId: string;

  @ApiPropertyOptional()
  @IsOptional()
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

export class GetListMyCourseDto extends IntersectionType(PageOptionsDto) {
  @ApiProperty({ required: true })
  @IsNotEmpty()
  @IsNumber()
  page: number;

  @ApiProperty({ required: true })
  @IsNotEmpty()
  @IsNumber()
  take: number;

  @ApiProperty({ type: Boolean, example: true, required: false })
  @IsOptional()
  @IsBoolean()
  @ToBoolean()
  recent: boolean;
}

export class GetProgressOfUserDto extends IntersectionType(PageOptionsDto) {}

export class GetSuggestCoursesWidgetDto {
  @ApiPropertyOptional({ description: 'Number of courses to return (1–6)', default: 6 })
  @IsOptional()
  @IsNumber()
  @Min(1)
  @Max(6)
  @Type(() => Number)
  limit?: number = 6;
}
