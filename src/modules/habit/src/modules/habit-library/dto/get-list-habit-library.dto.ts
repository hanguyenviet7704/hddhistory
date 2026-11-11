import { ApiPropertyOptional } from '@nestjs/swagger';
import { IsBoolean, IsEnum, IsMongoId, IsOptional } from 'class-validator';

import { ToBoolean } from '@utils/boolean.utils';

import { HabitLibraryStatus } from '../enum/habit-library.enum';

export class GetListHabitLibraryDto {
  @ApiPropertyOptional({
    description: 'Filter by category (category) id',
  })
  @IsOptional()
  @IsMongoId()
  categoryId?: string;

  @ApiPropertyOptional({
    description: 'Filter by keypoint id (habits suggested in this keypoint)',
  })
  @IsOptional()
  @IsMongoId()
  keypointId?: string;

  @ApiPropertyOptional({
    description:
      'Filter by course: habits attached to any keypoint of that course. ' +
      'Resolved through the same roadmap walk the import uses, so what an ' +
      'import writes is exactly what this returns.',
  })
  @IsOptional()
  @IsMongoId()
  courseId?: string;

  @ApiPropertyOptional({
    enum: HabitLibraryStatus,
    description: 'Filter by status; defaults to published (end-user view)',
  })
  @IsOptional()
  @IsEnum(HabitLibraryStatus)
  status?: HabitLibraryStatus;

  @ApiPropertyOptional({
    type: Boolean,
    example: true,
    description: 'Admin: return every status (overrides the published default)',
  })
  @IsOptional()
  @IsBoolean()
  @ToBoolean()
  isAll?: boolean;
}
