import {
  ApiProperty,
  ApiPropertyOptional,
  IntersectionType,
} from '@nestjs/swagger';
import { Transform } from 'class-transformer';
import {
  IsArray,
  IsBoolean,
  IsEnum,
  IsNotEmpty,
  IsNumber,
  IsOptional,
  IsString,
} from 'class-validator';

import { ToBoolean } from '@utils/boolean.utils';
import { PageOptionsDto } from '@utils/dto/paging/page.dto';
import { OnboardingSymptom } from '@utils/enum/course.enum';

import { CourseLevel, CourseStatus } from '../enum/course.enum';

export class GetListCourseDto extends IntersectionType(PageOptionsDto) {
  @ApiProperty({ required: true })
  @IsNotEmpty()
  @IsNumber()
  page: number;

  @ApiProperty({ required: true })
  @IsNotEmpty()
  @IsNumber()
  take: number;

  @ApiPropertyOptional({ enum: CourseLevel })
  @IsOptional()
  @IsEnum(CourseLevel)
  level?: CourseLevel;

  @ApiPropertyOptional({ enum: CourseStatus })
  @IsOptional()
  @IsEnum(CourseStatus)
  status?: CourseStatus = CourseStatus.PUBLISHED;

  /**
   * Restricts the query to these statuses, and wins over `status`/`isAll`.
   *
   * Deliberately undecorated: the global pipe runs with `whitelist: true`, so
   * a client cannot send it and ask a user-facing list for drafts. Only
   * services set it — see UserProgressService.getMyCourse.
   */
  statuses?: CourseStatus[];

  @IsArray()
  @ApiPropertyOptional({})
  @IsOptional()
  @IsString({ each: true })
  ids: string[];

  @ApiPropertyOptional({
    type: [String],
    example: ['68fe63134a13cd7ab2d5ac5a'],
    description: 'Filter courses by category ids.',
  })
  @IsOptional()
  @Transform(({ value }) => {
    if (value === undefined || value === null || value === '') return undefined;
    return Array.isArray(value) ? value : [value];
  })
  @IsArray()
  @IsString({ each: true })
  categoryIds?: string[];

  @ApiPropertyOptional({
    type: [String],
    example: [OnboardingSymptom.AMAZED_BY_HUMAN_BODY],
    description:
      'Filter categories by one or more onboarding introduce options.',
  })
  @IsOptional()
  @Transform(({ value }) => {
    if (value === undefined || value === null || value === '') return undefined;
    return Array.isArray(value) ? value : [value];
  })
  @IsArray()
  @IsString({ each: true })
  onboardingSymptoms?: string[];

  @ApiProperty({ type: Boolean, example: true, required: false })
  @IsOptional()
  @IsBoolean()
  @ToBoolean()
  isAll: boolean;
}
