import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { Type } from 'class-transformer';
import {
  IsInt,
  IsNotEmpty,
  IsOptional,
  IsString,
  Length,
  Max,
  Min,
} from 'class-validator';

export class GetCourseDropOffDto {
  @ApiProperty({ example: '663f1a2b3c4d5e6f7a8b9c0d' })
  @IsNotEmpty()
  @IsString()
  @Length(24)
  courseId: string;

  /**
   * Days without activity before a reader counts as STOPPED rather than merely
   * mid-course. `0` disables the filter and counts everyone in progress.
   *
   * Defaults to 7: shorter windows count the weekend-off crowd as drop-offs,
   * longer ones hide a real problem for a month.
   */
  @ApiPropertyOptional({ example: 7, default: 7 })
  @IsOptional()
  @Type(() => Number)
  @IsInt()
  @Min(0)
  @Max(365)
  staleDays?: number = 7;
}

/** Overview không nhận courseId — nó trả về MỌI khoá, cùng một định nghĩa "kẹt". */
export class GetDropOffOverviewDto {
  @ApiPropertyOptional({ example: 7, default: 7 })
  @IsOptional()
  @Type(() => Number)
  @IsInt()
  @Min(0)
  @Max(365)
  staleDays?: number = 7;
}
