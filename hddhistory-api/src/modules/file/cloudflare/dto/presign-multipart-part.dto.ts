import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { Type } from 'class-transformer';
import {
  IsNotEmpty,
  IsNumber,
  IsOptional,
  IsString,
  Min,
} from 'class-validator';

export class PresignMultipartPartDto {
  @ApiProperty()
  @IsNotEmpty()
  @IsString()
  key: string;

  @ApiProperty()
  @IsNotEmpty()
  @IsString()
  uploadId: string;

  @ApiProperty()
  @Type(() => Number)
  @IsNumber()
  @Min(1)
  partNumber: number;

  @ApiPropertyOptional({ description: 'Seconds', default: 3600 })
  @Type(() => Number)
  @IsOptional()
  @IsNumber()
  @Min(1)
  expiresIn?: number;
}
