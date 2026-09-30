import { ApiPropertyOptional } from '@nestjs/swagger';
import { Type } from 'class-transformer';
import { IsInt, IsOptional, IsString, Max, Min } from 'class-validator';

export class SearchEntityDto {
  @ApiPropertyOptional({
    example: 'tran hung dao',
    description: 'Từ khoá tìm theo tên thực thể; gõ không dấu vẫn khớp',
  })
  @IsOptional()
  @IsString()
  q?: string;

  @ApiPropertyOptional({ default: 20, minimum: 1, maximum: 100 })
  @IsOptional()
  @Type(() => Number)
  @IsInt()
  @Min(1)
  @Max(100)
  limit?: number = 20;
}

export class GetRelatedEntityDto {
  @ApiPropertyOptional({
    default: 2,
    minimum: 1,
    maximum: 3,
    description:
      'Số bước tối đa khi duyệt đồ thị. Giới hạn 3 vì mỗi bước thêm làm số ' +
      'đường đi tăng theo cấp số nhân, quá 3 bước thì gần như thực thể nào ' +
      'cũng "liên quan" và kết quả mất ý nghĩa.',
  })
  @IsOptional()
  @Type(() => Number)
  @IsInt()
  @Min(1)
  @Max(3)
  maxHops?: number = 2;

  @ApiPropertyOptional({ default: 20, minimum: 1, maximum: 100 })
  @IsOptional()
  @Type(() => Number)
  @IsInt()
  @Min(1)
  @Max(100)
  limit?: number = 20;
}
