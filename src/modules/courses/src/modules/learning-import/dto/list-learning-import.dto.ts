import { ApiPropertyOptional, IntersectionType } from '@nestjs/swagger';
import { Type } from 'class-transformer';
import { IsEnum, IsInt, IsOptional, Min } from 'class-validator';

import { PageOptionsDto } from '@utils/dto/paging/page.dto';

import { ImportJobStatus } from '../enum/learning-import.enum';

export class ListUserLessonDto extends IntersectionType(PageOptionsDto) {}

export class ListLearningImportAdminDto extends IntersectionType(
  PageOptionsDto,
) {
  @ApiPropertyOptional({
    enum: ImportJobStatus,
    description:
      'Narrow to one status. `interrupted` is derived on read and cannot be filtered on -- filter `processing` and check the returned status.',
  })
  @IsOptional()
  @IsEnum(ImportJobStatus)
  status?: ImportJobStatus;
}

export class UpdateUserLessonProgressDto {
  @ApiPropertyOptional({
    description: 'Index of the keypoint the reader was in.',
    example: 1,
    minimum: 0,
  })
  @IsOptional()
  @Type(() => Number)
  @IsInt()
  @Min(0)
  stopAtKeypointIndex?: number;

  @ApiPropertyOptional({
    description:
      'Index of the card the reader had reached, RELATIVE to that keypoint.',
    example: 3,
    minimum: 0,
  })
  @Type(() => Number)
  @IsInt()
  @Min(0)
  stopAtSectionIndex: number;
}
