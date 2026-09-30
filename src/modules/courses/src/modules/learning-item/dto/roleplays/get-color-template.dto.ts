import { ApiProperty, IntersectionType } from '@nestjs/swagger';
import { IsNotEmpty, IsNumber } from 'class-validator';

import { PageOptionsDto } from '@utils/dto/paging/page.dto';

export class GetListRoleplayColorTemplateDto extends IntersectionType(
  PageOptionsDto,
) {
  @ApiProperty({ required: true })
  @IsNotEmpty()
  @IsNumber()
  page: number;

  @ApiProperty({ required: true })
  @IsNotEmpty()
  @IsNumber()
  take: number;
}
