import { ApiPropertyOptional, IntersectionType } from '@nestjs/swagger';
import { IsEnum, IsMongoId, IsOptional, IsString } from 'class-validator';

import { PageOptionsDto } from '@utils/dto/paging/page.dto';

import { CommunityContentStatus } from '../../../enum/community.enum';

/**
 * The moderation table's filters. Hidden and deleted lines are included — the
 * point of the table is to see what was taken down and put it back if the call
 * was wrong.
 */
export class GetListCommunityChatDto extends IntersectionType(PageOptionsDto) {
  @ApiPropertyOptional({ enum: CommunityContentStatus })
  @IsOptional()
  @IsEnum(CommunityContentStatus)
  status?: CommunityContentStatus;

  @ApiPropertyOptional({ description: 'Room id or slug' })
  @IsOptional()
  @IsString()
  room?: string;

  @ApiPropertyOptional()
  @IsOptional()
  @IsMongoId()
  authorId?: string;

  @ApiPropertyOptional({ description: 'Searches the message body' })
  @IsOptional()
  @IsString()
  search?: string;
}
