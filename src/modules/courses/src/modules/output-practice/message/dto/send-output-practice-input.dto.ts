import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import {
  IsEnum,
  IsNotEmpty,
  IsNumber,
  IsOptional,
  IsString,
} from 'class-validator';

import { OutputPracticeSummaryDecisionValue } from '../../conversation/enum/output-practice-conversation.enum';
import { OutputPracticeMessageType } from '../enum/output-practice-message.enum';

export class SendOutputPracticeInputDto {
  @ApiProperty({ required: true, example: '68fe63134a13cd7ab2d5ac5a' })
  @IsNotEmpty()
  @IsString()
  conversationId: string;

  @ApiProperty({ enum: OutputPracticeMessageType })
  @IsNotEmpty()
  @IsEnum(OutputPracticeMessageType)
  type: OutputPracticeMessageType;

  @ApiPropertyOptional({ example: 'Noi dung user chat voi AI' })
  @IsOptional()
  @IsString()
  message?: string;

  @ApiPropertyOptional({
    example: 1,
    description:
      'For summary_decision: 1=Stop practicing here, 2=Start a new practice',
    enum: OutputPracticeSummaryDecisionValue,
  })
  @IsOptional()
  @IsNumber()
  value?: number;
}
