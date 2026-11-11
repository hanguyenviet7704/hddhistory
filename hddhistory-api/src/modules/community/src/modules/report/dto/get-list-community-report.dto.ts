import { ApiPropertyOptional, IntersectionType } from '@nestjs/swagger';
import { IsEnum, IsOptional } from 'class-validator';

import { PageOptionsDto } from '@utils/dto/paging/page.dto';

import {
  CommunityReportReason,
  CommunityReportStatus,
  CommunityTargetType,
} from '../../../enum/community.enum';

export class GetListCommunityReportDto extends IntersectionType(
  PageOptionsDto,
) {
  @ApiPropertyOptional({
    enum: CommunityReportStatus,
    description: 'Defaults to PENDING — the queue a moderator actually works',
  })
  @IsOptional()
  @IsEnum(CommunityReportStatus)
  status?: CommunityReportStatus;

  @ApiPropertyOptional({ enum: CommunityTargetType })
  @IsOptional()
  @IsEnum(CommunityTargetType)
  targetType?: CommunityTargetType;

  @ApiPropertyOptional({ enum: CommunityReportReason })
  @IsOptional()
  @IsEnum(CommunityReportReason)
  reason?: CommunityReportReason;
}
