import { ApiProperty } from '@nestjs/swagger';
import { IsEnum, IsNotEmpty, IsString } from 'class-validator';

import {
  OutputPracticeMessageRole,
  OutputPracticeMessageType,
} from '../enum/output-practice-message.enum';

export class CreateOutputPracticeMessageDto {
  @ApiProperty({ required: true, example: '68fe63134a13cd7ab2d5ac5a' })
  @IsNotEmpty()
  @IsString()
  conversationId: string;

  @ApiProperty({ required: true, example: 'Hello AI tutor' })
  @IsNotEmpty()
  @IsString()
  content: string;

  @ApiProperty({ enum: OutputPracticeMessageType })
  @IsNotEmpty()
  @IsEnum(OutputPracticeMessageType)
  type: OutputPracticeMessageType;

  @ApiProperty({ enum: OutputPracticeMessageRole })
  @IsNotEmpty()
  @IsEnum(OutputPracticeMessageRole)
  role: OutputPracticeMessageRole;
}
