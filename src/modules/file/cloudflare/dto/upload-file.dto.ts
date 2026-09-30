import { ApiProperty } from '@nestjs/swagger';
import { IsOptional, IsString } from 'class-validator';

export class UploadFileDto {
  @ApiProperty({ required: false, example: 'anh1.png' })
  @IsOptional()
  @IsString()
  key: string;

  @ApiProperty({ required: false, example: 'prefix_' })
  @IsOptional()
  @IsString()
  prefix: string;

  @ApiProperty({ required: false, example: 'my-folder' })
  @IsOptional()
  @IsString()
  folder: string;
}
