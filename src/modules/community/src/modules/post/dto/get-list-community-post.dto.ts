import { ApiPropertyOptional, IntersectionType } from '@nestjs/swagger';
import { IsEnum, IsIn, IsMongoId, IsOptional, IsString } from 'class-validator';

import { PageOptionsDto } from '@utils/dto/paging/page.dto';

import {
  CommunityContentStatus,
  CommunityPostType,
} from '../../../enum/community.enum';
import { COMMUNITY_LOCALES } from '../../../interface/community.interface';

// Admin moderation table. Unlike the reader feed this can see hidden and
// deleted rows — that is the whole point of it.
export class GetListCommunityPostDto extends IntersectionType(PageOptionsDto) {
  @ApiPropertyOptional({ enum: CommunityContentStatus })
  @IsOptional()
  @IsEnum(CommunityContentStatus)
  status?: CommunityContentStatus;

  @ApiPropertyOptional({ enum: CommunityPostType })
  @IsOptional()
  @IsEnum(CommunityPostType)
  type?: CommunityPostType;

  @ApiPropertyOptional()
  @IsOptional()
  @IsMongoId()
  topicId?: string;

  @ApiPropertyOptional({ enum: COMMUNITY_LOCALES })
  @IsOptional()
  @IsString()
  @IsIn(COMMUNITY_LOCALES as unknown as string[])
  locale?: string;

  @ApiPropertyOptional()
  @IsOptional()
  @IsMongoId()
  authorId?: string;
}
