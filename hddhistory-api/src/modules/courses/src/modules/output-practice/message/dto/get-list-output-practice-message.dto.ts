import {
  ApiProperty,
  ApiPropertyOptional,
  IntersectionType,
} from '@nestjs/swagger';
import { Type } from 'class-transformer';
import { IsNotEmpty, IsNumber, IsOptional, IsString } from 'class-validator';

import { PageOptionsDto } from '@utils/dto/paging/page.dto';

export class GetListOutputPracticeMessageDto extends IntersectionType(
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

  @ApiProperty({ required: true })
  @IsNotEmpty()
  @IsString()
  conversationId: string;

  @ApiPropertyOptional({
    description:
      'Only fetch messages with seq < this value (for backward pagination)',
    example: 120,
  })
  @Type(() => Number)
  @IsOptional()
  @IsNumber()
  seq?: number;
}
