import { ApiProperty, ApiPropertyOptional, IntersectionType } from '@nestjs/swagger';
import { IsEnum, IsNotEmpty, IsNumber, IsOptional, IsString, Min } from 'class-validator';

import { PageOptionsDto } from '@utils/dto/paging/page.dto';
import { OrderType } from '@utils/type/orderByType';

export class GetListUserVideoLessonActivityDto extends IntersectionType(PageOptionsDto) {
  @ApiPropertyOptional({ enum: OrderType, default: OrderType.ASC })
  @IsEnum(OrderType)
  @IsOptional()
  readonly order?: OrderType = OrderType.ASC;

  @ApiPropertyOptional({
    default: 'atSecond',
  })
  @IsOptional()
  readonly orderBy?: string = 'atSecond';

  @ApiPropertyOptional({ required: false, example: '68fe63134a13cd7ab2d5ac5a' })
  @IsOptional()
  @IsString()
  courseId?: string;

  @ApiPropertyOptional({ required: false, example: 'section-1' })
  @IsOptional()
  @IsString()
  nodeId?: string;

  @ApiPropertyOptional({ required: false, example: '68fe63134a13cd7ab2d5ac5b' })
  @IsOptional()
  @IsString()
  lessonId?: string;
}

export class CreateUserVideoLessonNoteDto {
  @ApiProperty({ required: true, example: '68fe63134a13cd7ab2d5ac5a' })
  @IsNotEmpty()
  @IsString()
  courseId: string;

  @ApiProperty({ required: true, example: 'section-1' })
  @IsNotEmpty()
  @IsString()
  nodeId: string;

  @ApiProperty({ required: true, example: '68fe63134a13cd7ab2d5ac5b' })
  @IsNotEmpty()
  @IsString()
  lessonId: string;

  @ApiProperty({ required: true, example: 'Important idea at this timestamp' })
  @IsNotEmpty()
  @IsString()
  content: string;

  @ApiPropertyOptional({ required: false, example: 87 })
  @IsOptional()
  @IsNumber()
  @Min(0)
  atSecond?: number;
}

export class UpdateUserVideoLessonNoteDto {
  @ApiPropertyOptional({ required: false, example: 'Updated note content' })
  @IsOptional()
  @IsString()
  content?: string;

  @ApiPropertyOptional({ required: false, example: 92 })
  @IsOptional()
  @IsNumber()
  @Min(0)
  atSecond?: number;
}
