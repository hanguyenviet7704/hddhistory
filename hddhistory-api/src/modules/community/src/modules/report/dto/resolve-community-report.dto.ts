import { ApiProperty } from '@nestjs/swagger';
import { IsEnum, IsIn } from 'class-validator';

import { CommunityReportStatus } from '../../../enum/community.enum';

export class ResolveCommunityReportDto {
  @ApiProperty({
    enum: [
      CommunityReportStatus.RESOLVED_HIDDEN,
      CommunityReportStatus.RESOLVED_KEPT,
    ],
    description:
      'RESOLVED_HIDDEN also hides the reported content; RESOLVED_KEPT leaves it up',
  })
  @IsEnum(CommunityReportStatus)
  @IsIn([
    CommunityReportStatus.RESOLVED_HIDDEN,
    CommunityReportStatus.RESOLVED_KEPT,
  ])
  status: CommunityReportStatus;
}
