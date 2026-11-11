import { ApiPropertyOptional, IntersectionType } from '@nestjs/swagger';
import { IsEnum, IsOptional, IsString } from 'class-validator';

import { PageOptionsDto } from '@utils/dto/paging/page.dto';

import { CommunityRoomSuggestionStatus } from '../../../enum/community.enum';

export class GetListCommunityRoomSuggestionDto extends IntersectionType(
  PageOptionsDto,
) {
  @ApiPropertyOptional({ enum: CommunityRoomSuggestionStatus })
  @IsOptional()
  @IsEnum(CommunityRoomSuggestionStatus)
  status?: CommunityRoomSuggestionStatus;

  @ApiPropertyOptional({ description: 'Filter to one language, e.g. "vi"' })
  @IsOptional()
  @IsString()
  locale?: string;
}
