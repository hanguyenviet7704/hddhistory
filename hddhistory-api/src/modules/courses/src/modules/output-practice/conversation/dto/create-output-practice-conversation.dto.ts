import { ApiProperty } from '@nestjs/swagger';
import { IsNotEmpty, IsString } from 'class-validator';

export class CreateOutputPracticeConversationDto {
  @ApiProperty({
    required: true,
    example: '2e7868b5-1fb6-4317-9de7-f06ade57f0cc',
    description: 'Roadmap node id',
  })
  @IsNotEmpty()
  @IsString()
  sectionId: string;

  @ApiProperty({
    required: true,
    example: 'vi',
    description: 'Language for AI output practice',
  })
  @IsNotEmpty()
  @IsString()
  language: string;
}
