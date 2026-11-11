import { ApiPropertyOptional, IntersectionType } from '@nestjs/swagger';
import { Type } from 'class-transformer';
import {
  IsBoolean,
  IsDate,
  IsEnum,
  IsMongoId,
  IsOptional,
} from 'class-validator';

import { ToBoolean } from '@utils/boolean.utils';
import { PageOptionsDto } from '@utils/dto/paging/page.dto';

import { CommunityFeedSort } from '../../../enum/community.enum';

export class GetCommunityFeedDto extends IntersectionType(PageOptionsDto) {
  @ApiPropertyOptional({ description: 'Scope the feed to one topic' })
  @IsOptional()
  @IsMongoId()
  topicId?: string;

  @ApiPropertyOptional({
    type: Boolean,
    description:
      'Only the threads the reader put the bell on (the "Đang theo dõi" tab). This is per-POST, not per-topic: the tab lists conversations the reader asked to be told about.',
  })
  @IsOptional()
  @IsBoolean()
  @ToBoolean()
  followedOnly?: boolean;

  @ApiPropertyOptional({
    enum: CommunityFeedSort,
    description: 'Defaults to RECENT (newest first)',
  })
  @IsOptional()
  @IsEnum(CommunityFeedSort)
  sort?: CommunityFeedSort;

  @ApiPropertyOptional({
    description:
      'Server timestamp returned by page 1. Pass it back on later pages so a post written in between cannot appear on two pages.',
  })
  @IsOptional()
  @IsDate()
  @Type(() => Date)
  anchorAt?: Date;
}
