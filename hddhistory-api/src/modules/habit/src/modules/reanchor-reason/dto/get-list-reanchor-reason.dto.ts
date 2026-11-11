import { ApiPropertyOptional } from '@nestjs/swagger';
import { IsBoolean, IsEnum, IsMongoId, IsOptional } from 'class-validator';

import { ToBoolean } from '@utils/boolean.utils';

import { ReanchorReasonStatus } from '../enum/reanchor-reason.enum';

export class GetListReanchorReasonDto {
  @ApiPropertyOptional({
    description: 'Filter by course id',
  })
  @IsOptional()
  @IsMongoId()
  courseId?: string;

  @ApiPropertyOptional({
    enum: ReanchorReasonStatus,
    description: 'Filter by status; defaults to published (end-user view)',
  })
  @IsOptional()
  @IsEnum(ReanchorReasonStatus)
  status?: ReanchorReasonStatus;

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
