import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { Type } from 'class-transformer';
import {
  IsArray,
  IsNotEmpty,
  IsNumber,
  IsOptional,
  IsString,
  ValidateNested,
} from 'class-validator';

import { DocumentDto } from '../document.dto';

export class TheoryDto {
  @ApiProperty({ required: true })
  @IsNotEmpty()
  @IsNumber()
  id: number;

  @ApiProperty({ required: false, example: 'id of tag' })
  @IsOptional()
  @IsString()
  tagId: string;

  @IsArray()
  @ApiPropertyOptional({
    type: [DocumentDto],
    required: false,
    example: DocumentDto,
  })
  @Type(() => DocumentDto)
  @IsOptional()
  @ValidateNested({ each: true })
  document: DocumentDto[];
}
