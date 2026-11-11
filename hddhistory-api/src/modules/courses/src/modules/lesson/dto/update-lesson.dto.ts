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

import { CreateLessonDto } from './create-lesson.dto';

export class UpdateLessonDto extends PartialType(CreateLessonDto) {}

class LessonIndexDto {
  @ApiProperty()
  @IsNotEmpty()
  @IsString()
  id: string;

  @ApiProperty()
  @IsNotEmpty()
  @IsNumber()
  index: number;
}

export class UpdateLessonIndexDto {
  @ApiProperty()
  @IsNotEmpty()
  @IsString()
  courseId: string;

  @IsArray()
  @ApiProperty({
    type: [LessonIndexDto],
  })
  @ArrayNotEmpty()
  @Type(() => LessonIndexDto)
  @ValidateNested({ each: true })
  lessons: LessonIndexDto[];
}
