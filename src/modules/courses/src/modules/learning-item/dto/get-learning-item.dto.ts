import {
  ApiProperty,
  ApiPropertyOptional,
  IntersectionType,
} from '@nestjs/swagger';
import {
  IsEnum,
  IsNotEmpty,
  IsNumber,
  IsOptional,
  IsString,
} from 'class-validator';

import { PageOptionsDto } from '@utils/dto/paging/page.dto';

import { LearningItemType } from '../enum/learning-item.enum';

export class GetListLearningItemDto extends IntersectionType(PageOptionsDto) {
  @ApiProperty({ required: true })
  @IsNotEmpty()
  @IsNumber()
  page: number;

  @ApiProperty({ required: true })
  @IsNotEmpty()
  @IsNumber()
  take: number;

  @ApiPropertyOptional({ enum: LearningItemType })
  @IsOptional()
  @IsEnum(LearningItemType)
  type?: LearningItemType;

  @ApiPropertyOptional()
  @IsOptional()
  @IsString()
  keypointId: string;
}
