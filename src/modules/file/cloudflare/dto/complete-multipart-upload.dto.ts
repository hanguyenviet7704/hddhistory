import { ApiProperty } from '@nestjs/swagger';
import { Type } from 'class-transformer';
import {
  IsArray,
  IsNotEmpty,
  IsNumber,
  IsString,
  Min,
  ValidateNested,
} from 'class-validator';

export class MultipartUploadPartDto {
  @ApiProperty()
  @IsNotEmpty()
  @IsString()
  ETag: string;

  @ApiProperty()
  @Type(() => Number)
  @IsNumber()
  @Min(1)
  PartNumber: number;
}

export class CompleteMultipartUploadDto {
  @ApiProperty()
  @IsNotEmpty()
  @IsString()
  key: string;

  @ApiProperty()
  @IsNotEmpty()
  @IsString()
  uploadId: string;

  @ApiProperty({ type: [MultipartUploadPartDto] })
  @IsArray()
  @ValidateNested({ each: true })
  @Type(() => MultipartUploadPartDto)
  parts: MultipartUploadPartDto[];
}
