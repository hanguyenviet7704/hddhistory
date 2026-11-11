import {
  ApiProperty,
  ApiPropertyOptional,
  IntersectionType,
} from '@nestjs/swagger';
import {
  IsEnum,
  IsNotEmpty,
  IsOptional,
  IsString,
  MaxLength,
} from 'class-validator';

import { PageOptionsDto } from '@utils/dto/paging/page.dto';

import { SavedCourseStatus } from '../enum/saved-course.enum';

export class SaveCourseDto {
  // Accept any non-empty id string, the same latitude `recently-viewed` takes:
  // an id that matches no published course simply never resolves on read, and
  // failing the save would be a worse answer than a bookmark that shows nothing.
  @ApiProperty()
  @IsNotEmpty()
  @IsString()
  @MaxLength(64)
  courseId: string;
}

export class GetSavedCoursesDto extends IntersectionType(PageOptionsDto) {
  @ApiPropertyOptional({ enum: SavedCourseStatus })
  @IsOptional()
  @IsEnum(SavedCourseStatus)
  status?: SavedCourseStatus;
}
