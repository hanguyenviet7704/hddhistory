import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { ArrayMinSize, IsArray, IsOptional, IsString } from 'class-validator';

export class SubmitInAppSurveyResponseDto {
  @ApiPropertyOptional({
    description: 'Survey session id returned when Q1 was shown.',
    example: '66503f1444484d65b8598f85',
  })
  @IsOptional()
  @IsString()
  sessionId?: string;

  @ApiProperty({
    description: 'Selected branch id.',
    example: 'c4c81fa2-0802-4f3b-bf6f-ff1aa02dc58e',
  })
  @IsString()
  branchId: string;

  @ApiProperty({
    type: String,
    isArray: true,
    description: 'Selected closed-question option ids.',
    example: ['7f8d4b1f-0f1f-4a70-8e50-97c4c53a1b11'],
  })
  @IsArray()
  @ArrayMinSize(1)
  @IsString({ each: true })
  selectedOptionIds: string[];

  @ApiPropertyOptional({
    description: 'Optional free-form feedback from open question.',
    example: 'The app is helpful, but loading could be faster.',
  })
  @IsOptional()
  @IsString()
  feedback?: string;
}
