import { ApiPropertyOptional, IntersectionType } from '@nestjs/swagger';
import { IsBoolean, IsDateString, IsOptional } from 'class-validator';

import { ToBoolean } from '@utils/boolean.utils';
import { PageOptionsDto } from '@utils/dto/paging/page.dto';

// `search` (matches slug/name) and paging fields are inherited from
// PageOptionsDto.
export class GetListDownloadLinkDto extends IntersectionType(PageOptionsDto) {
  @ApiPropertyOptional({ type: Boolean, example: true })
  @IsOptional()
  @IsBoolean()
  @ToBoolean()
  isActive?: boolean;
}

export class GetDownloadLinkStatsDto {
  @ApiPropertyOptional({
    example: '2026-07-01',
    description: 'ISO date. Defaults to 30 days ago',
  })
  @IsOptional()
  @IsDateString()
  from?: string;

  @ApiPropertyOptional({
    example: '2026-07-31',
    description: 'ISO date, inclusive. Defaults to today',
  })
  @IsOptional()
  @IsDateString()
  to?: string;
}
