import { ApiProperty } from '@nestjs/swagger';
import { IsNotEmpty, IsString } from 'class-validator';

export class TopicDto {
  @ApiProperty({
    example: 'f3eWxXFxT3i4z2_9pn9cKX:APA91bF...',
    description: 'Firebase registration token',
  })
  @IsString()
  @IsNotEmpty()
  token: string;

  @ApiProperty({
    example: 'course-updates',
    description: 'Name of the topic to subscribe to',
  })
  @IsString()
  @IsNotEmpty()
  topic: string;
}
