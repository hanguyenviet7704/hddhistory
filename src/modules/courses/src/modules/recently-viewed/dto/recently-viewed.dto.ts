import { ApiProperty } from '@nestjs/swagger';
import { IsNotEmpty, IsString, MaxLength } from 'class-validator';

export class RecordCourseViewDto {
  // Best-effort view tracking — accept any non-empty id string. Ids that do
  // not match a real course simply won't resolve on read.
  @ApiProperty()
  @IsNotEmpty()
  @IsString()
  @MaxLength(64)
  courseId: string;
}
