import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { Type } from 'class-transformer';
import {
  ArrayNotEmpty,
  IsArray,
  IsBoolean,
  IsDate,
  IsInt,
  IsNotEmpty,
  IsOptional,
  IsString,
  Max,
  MaxLength,
  Min,
  ValidateNested,
} from 'class-validator';

export class ExperimentArmDto {
  @ApiProperty({ example: '6a50a323f80763639535361a' })
  @IsString()
  @IsNotEmpty()
  courseId: string;

  @ApiProperty({ example: 'v1.0.0' })
  @IsString()
  @IsNotEmpty()
  tagA: string;

  @ApiProperty({ example: 'v1.1.0' })
  @IsString()
  @IsNotEmpty()
  tagB: string;
}

export class CreateContentExperimentDto {
  @ApiProperty({
    example: '3conlonbeo',
    description:
      'Mã đợt. PHẢI đổi mỗi đợt: dùng lại là trả mọi người về đúng nhánh cũ, ' +
      'và số liệu đã đóng dấu key cũ sẽ lẫn vào phễu đợt mới.',
  })
  @IsString()
  @IsNotEmpty()
  @MaxLength(64)
  key: string;

  @ApiProperty({
    example: 50,
    minimum: 0,
    maximum: 100,
    description:
      'Tỉ lệ vào nhánh B. 0 và 100 hợp lệ để thu hẹp đợt về một nhánh mà ' +
      'không xoá đợt (xoá là mất key mà số liệu đang trỏ tới).',
  })
  @IsInt()
  @Min(0)
  @Max(100)
  percentB: number;

  @ApiProperty({
    example: '2026-09-08T00:00:00.000Z',
    description:
      'Mốc quyết ai vào đợt: người đã bắt đầu khoá TRƯỚC mốc này giữ nguyên ' +
      'tag đang phát hành, không bị đổi nội dung giữa đường.',
  })
  @Type(() => Date)
  @IsDate()
  startedAt: Date;

  @ApiProperty({ type: [ExperimentArmDto] })
  @IsArray()
  @ArrayNotEmpty()
  @ValidateNested({ each: true })
  @Type(() => ExperimentArmDto)
  arms: ExperimentArmDto[];

  @ApiPropertyOptional({ example: 'Thử lối viết ngắn hơn' })
  @IsOptional()
  @IsString()
  @MaxLength(500)
  note?: string;
}

export class SetExperimentEnabledDto {
  @ApiProperty({ example: true })
  @IsBoolean()
  enabled: boolean;
}
