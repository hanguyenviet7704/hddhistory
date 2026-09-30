import { ApiPropertyOptional, IntersectionType } from '@nestjs/swagger';
import { IsEnum, IsMongoId, IsOptional } from 'class-validator';

import { PageOptionsDto } from '@utils/dto/paging/page.dto';

import { CommunityContentStatus } from '../../../enum/community.enum';

export class GetListCommunityCommentDto extends IntersectionType(
  PageOptionsDto,
) {
  @ApiPropertyOptional({ enum: CommunityContentStatus })
  @IsOptional()
  @IsEnum(CommunityContentStatus)
  status?: CommunityContentStatus;

  @ApiPropertyOptional()
  @IsOptional()
  @IsMongoId()
  postId?: string;

  @ApiPropertyOptional()
  @IsOptional()
  @IsMongoId()
  authorId?: string;
}
