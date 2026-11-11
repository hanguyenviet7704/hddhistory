import { ApiPropertyOptional, IntersectionType } from '@nestjs/swagger';
import { IsBoolean, IsOptional } from 'class-validator';

import { ToBoolean } from '@utils/boolean.utils';
import { PageOptionsDto } from '@utils/dto/paging/page.dto';

// `search` (matches code/owner) and paging fields are inherited from
// PageOptionsDto.
export class GetListVoucherDto extends IntersectionType(PageOptionsDto) {
  @ApiPropertyOptional({ type: Boolean, example: true })
  @IsOptional()
  @IsBoolean()
  @ToBoolean()
  isActive?: boolean;
}
