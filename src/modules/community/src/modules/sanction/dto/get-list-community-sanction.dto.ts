import { ApiPropertyOptional, IntersectionType } from '@nestjs/swagger';
import { IsMongoId, IsOptional } from 'class-validator';

import { PageOptionsDto } from '@utils/dto/paging/page.dto';

export class GetListCommunitySanctionDto extends IntersectionType(
  PageOptionsDto,
) {
  @ApiPropertyOptional()
  @IsOptional()
  @IsMongoId()
  userId?: string;
}
