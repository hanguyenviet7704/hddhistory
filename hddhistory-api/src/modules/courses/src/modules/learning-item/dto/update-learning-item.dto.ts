import { ApiProperty, PartialType } from '@nestjs/swagger';
import { Type } from 'class-transformer';
import {
  ArrayNotEmpty,
  IsArray,
  IsNotEmpty,
  IsNumber,
  IsString,
  ValidateNested,
} from 'class-validator';

import { CreateLearningItemDto } from './create-learning-item.dto';

export class UpdateLearningItemDto extends PartialType(CreateLearningItemDto) {}

class LearningItemIndexDto {
  @ApiProperty({ required: true, example: 1 })
  @IsNotEmpty()
  @IsString()
  id: string;

  @ApiProperty({ required: true, example: 1 })
  @IsNotEmpty()
  @IsNumber()
  index: number;
}

export class UpdateLearningItemIndexDto {
  @ApiProperty({ required: true, example: '68fe63134a13cd7ab2d5ac5a' })
  @IsNotEmpty()
  @IsString()
  keypointId: string;

  @IsArray()
  @ApiProperty({
    type: [LearningItemIndexDto],
    example: LearningItemIndexDto,
    required: true,
  })
  @ArrayNotEmpty()
  @Type(() => LearningItemIndexDto)
  @ValidateNested({ each: true })
  learningItems: LearningItemIndexDto[];
}
