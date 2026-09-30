import { ApiProperty } from '@nestjs/swagger';
import { IsString, IsNotEmpty, IsOptional } from 'class-validator';

export class CreateAvatarDto {
  @ApiProperty()
  @IsOptional()
  @IsString()
  _id: string;

  @ApiProperty({
    required: true,
    description: 'Name of the avatar',
    example: 'Kacy',
  })
  @IsString()
  @IsNotEmpty()
  name: string;

  @ApiProperty({
    required: true,
    description: 'Avatar URL',
    example: 'https://example.com/avatar.png',
  })
  @IsString()
  @IsNotEmpty()
  url: string;
}
