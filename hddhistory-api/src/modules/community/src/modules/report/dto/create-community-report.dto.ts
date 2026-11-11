import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { IsEnum, IsMongoId, IsNotEmpty, IsOptional, IsString, MaxLength } from 'class-validator';

import {
  CommunityReportReason,
  CommunityTargetType,
} from '../../../enum/community.enum';

export class CreateCommunityReportDto {
  @ApiProperty({ enum: CommunityTargetType })
  @IsEnum(CommunityTargetType)
  targetType: CommunityTargetType;

  @ApiProperty()
  @IsNotEmpty()
  @IsMongoId()
  targetId: string;

  @ApiProperty({ enum: CommunityReportReason })
  @IsEnum(CommunityReportReason)
  reason: CommunityReportReason;

  @ApiPropertyOptional()
  @IsOptional()
  @IsString()
  @MaxLength(1000)
  note?: string;
}
