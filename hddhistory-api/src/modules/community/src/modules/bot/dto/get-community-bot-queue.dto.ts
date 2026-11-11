import { ApiPropertyOptional, IntersectionType } from '@nestjs/swagger';
import { IsEnum, IsOptional, IsString } from 'class-validator';

import { PageOptionsDto } from '@utils/dto/paging/page.dto';

import {
  CommunityBotKind,
  CommunityBotQueueStatus,
} from '../enum/community-bot.enum';

export class GetCommunityBotQueueDto extends IntersectionType(PageOptionsDto) {
  @ApiPropertyOptional({ enum: CommunityBotQueueStatus })
  @IsOptional()
  @IsEnum(CommunityBotQueueStatus)
  status?: CommunityBotQueueStatus;

  @ApiPropertyOptional({ enum: CommunityBotKind })
  @IsOptional()
  @IsEnum(CommunityBotKind)
  kind?: CommunityBotKind;

  @ApiPropertyOptional({ description: 'One generation run' })
  @IsOptional()
  @IsString()
  runId?: string;

  @ApiPropertyOptional()
  @IsOptional()
  @IsString()
  roomId?: string;
}
