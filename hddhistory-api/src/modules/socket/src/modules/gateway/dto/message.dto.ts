import { ApiProperty } from '@nestjs/swagger';
import { IsString } from 'class-validator';

export class StreamMessageDto {
  @ApiProperty()
  @IsString()
  roomId: string;

  @ApiProperty()
  @IsString()
  message: string;

  @ApiProperty()
  @IsString()
  sender: string; // userId hoặc username
}
