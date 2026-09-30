import { ApiPropertyOptional, IntersectionType } from '@nestjs/swagger';
import { IsBoolean, IsOptional } from 'class-validator';

import { ToBoolean } from '@utils/boolean.utils';
import { PageOptionsDto } from '@utils/dto/paging/page.dto';

export class GetListCommunityTopicDto extends IntersectionType(
  PageOptionsDto,
) {
  @ApiPropertyOptional({
    type: Boolean,
    description: 'Omit to include both active and inactive topics',
  })
  @IsOptional()
  @IsBoolean()
  @ToBoolean()
  isActive?: boolean;
}
