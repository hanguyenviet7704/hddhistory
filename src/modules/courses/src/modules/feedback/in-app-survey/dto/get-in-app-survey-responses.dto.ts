import { ApiProperty, IntersectionType } from '@nestjs/swagger';
import { Type } from 'class-transformer';
import { IsNotEmpty, IsNumber, IsOptional, IsString } from 'class-validator';

import { PageOptionsDto } from '@utils/dto/paging/page.dto';

export class GetInAppSurveyResponsesDto extends IntersectionType(
  PageOptionsDto,
) {
  @ApiProperty({ required: true, default: 1 })
  @Type(() => Number)
  @IsNotEmpty()
  @IsNumber()
  page: number;

  @ApiProperty({ required: true, default: 20 })
  @Type(() => Number)
  @IsNotEmpty()
  @IsNumber()
  take: number;

  @ApiProperty({
    required: false,
    description: 'Filter responses by user id.',
  })
  @IsOptional()
  @IsString()
  userId?: string;
}
