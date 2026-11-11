import {
  ApiProperty,
  ApiPropertyOptional,
  IntersectionType,
} from '@nestjs/swagger';
import {
  IsNotEmpty,
  IsNumber,
  IsOptional,
  IsString,
} from 'class-validator';

import { PageOptionsDto } from '@utils/dto/paging/page.dto';

export class GetListOutputPracticeConversationDto extends IntersectionType(
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

  @ApiPropertyOptional({ description: 'Roadmap node id' })
  @IsOptional()
  @IsString()
  sectionId?: string;

  @ApiPropertyOptional({ description: 'AI thread id' })
  @IsOptional()
  @IsString()
  threadId?: string;
}
