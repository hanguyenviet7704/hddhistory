import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { Type } from 'class-transformer';
import {
  IsArray,
  IsIn,
  IsNotEmptyObject,
  IsNumber,
  IsObject,
  IsOptional,
  IsString,
  ValidateNested,
} from 'class-validator';

import { IsMultiLangString } from '@utils/dto/multi-languge';

export class ReanchorReasonImportRow {
  @ApiPropertyOptional({
    description: 'Existing reason _id, to update that exact record in place',
  })
  @IsOptional()
  @IsString()
  id?: string;

  @ApiProperty({ description: "Course title.en (portable key)" })
  @IsString()
  course: string;

  @ApiProperty({ example: 1, description: '1-based order within the course' })
  @IsNumber()
  index: number;

  @ApiProperty({
    type: Object,
    example: { en: 'Criticized, you react and then regret it', vi: 'Bị chê, bạn phản ứng rồi tiếc' },
  })
  @IsObject()
  @IsNotEmptyObject()
  @IsMultiLangString()
  reason: Record<string, string>;
}

export class ImportReanchorReasonDto {
  @ApiPropertyOptional({ enum: ['replace'], default: 'replace' })
  @IsOptional()
  @IsIn(['replace'])
  mode?: 'replace';

  @ApiProperty({ type: [ReanchorReasonImportRow] })
  @IsArray()
  @ValidateNested({ each: true })
  @Type(() => ReanchorReasonImportRow)
  rows: ReanchorReasonImportRow[];
}
