import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { IsNotEmpty, IsOptional, IsString } from 'class-validator';

export class InitMultipartUploadDto {
  @ApiProperty({ example: 'audio.mp3' })
  @IsNotEmpty()
  @IsString()
  filename: string;

  @ApiProperty({ example: 'audio/mpeg' })
  @IsNotEmpty()
  @IsString()
  contentType: string;

  @ApiPropertyOptional()
  @IsOptional()
  @IsString()
  key?: string;

  @ApiPropertyOptional()
  @IsOptional()
  @IsString()
  prefix?: string;

  @ApiPropertyOptional()
  @IsOptional()
  @IsString()
  folder?: string;
}
