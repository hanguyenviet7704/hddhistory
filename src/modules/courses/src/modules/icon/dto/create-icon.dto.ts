import { ApiProperty } from '@nestjs/swagger';
import { IsString, IsNotEmpty, IsOptional } from 'class-validator';

export class CreateIconDto {
  @ApiProperty()
  @IsOptional()
  @IsString()
  _id: string;

  @ApiProperty({
    required: true,
    description: 'Icon URL',
    example: 'https://example.com/avatar.png',
  })
  @IsString()
  @IsNotEmpty()
  url: string;
}
