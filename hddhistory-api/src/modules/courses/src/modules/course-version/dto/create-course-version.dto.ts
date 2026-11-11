import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { IsBoolean, IsOptional, IsString, MaxLength } from 'class-validator';

export class CreateCourseVersionDto {
  @ApiProperty({
    example: 'v1.0.1',
    description:
      'Tag name, vMAJOR.MINOR.PATCH with no leading zeros. Must not already exist on this course.',
  })
  @IsString()
  tag: string;

  @ApiPropertyOptional({ example: 'Sửa lại phần ghi chú bài 2' })
  @IsOptional()
  @IsString()
  @MaxLength(500)
  note?: string;

  @ApiPropertyOptional({
    default: false,
    description:
      'Publish immediately: point the course at this tag. Off by default so freezing content and publishing it stay separate decisions.',
  })
  @IsOptional()
  @IsBoolean()
  setCurrent?: boolean;
}

export class SetCurrentVersionDto {
  @ApiProperty({ example: 'v1.0.0' })
  @IsString()
  tag: string;
}
