import { ApiProperty } from '@nestjs/swagger';
import { IsNotEmpty, IsString, IsUrl } from 'class-validator';

export class RangeCheckDto {
  @ApiProperty({ example: 'https://cdn.example.com/audio.mp3' })
  @IsNotEmpty()
  @IsString()
  @IsUrl({ require_protocol: true })
  url: string;
}
