import { ApiPropertyOptional } from '@nestjs/swagger';
import { IsEnum, IsOptional, IsString, MaxLength } from 'class-validator';

import { CommunityContentStatus } from '../../../enum/community.enum';

export class ModerateCommunityCommentDto {
  @ApiPropertyOptional({ enum: CommunityContentStatus })
  @IsOptional()
  @IsEnum(CommunityContentStatus)
  status?: CommunityContentStatus;

  @ApiPropertyOptional()
  @IsOptional()
  @IsString()
  @MaxLength(500)
  hiddenReason?: string;
}
