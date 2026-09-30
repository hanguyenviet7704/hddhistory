import { ApiPropertyOptional } from '@nestjs/swagger';
import { IsArray, IsBoolean, IsNumber, IsOptional } from 'class-validator';

export class OnboardingDto {
  @ApiPropertyOptional({ type: Boolean, required: false, example: true })
  @IsOptional()
  @IsBoolean()
  isNativeEnglishSpeaker: boolean;

  @ApiPropertyOptional({ example: 1, required: false })
  @IsOptional()
  @IsNumber()
  comfortableLearningTime: number;

  @ApiPropertyOptional({
    required: false,
    example: 1,
    description: 'id of dailyLearningGoal onboarding',
  })
  @IsOptional()
  @IsNumber()
  dailyLearningGoal: number;

  @ApiPropertyOptional({
    required: false,
    example: 1,
    description: 'id of dailyLearningGoal onboarding',
  })
  @IsOptional()
  @IsNumber()
  learningGoal: number;

  @IsArray()
  @ApiPropertyOptional({
    type: [Number],
    required: false,
    example: [1, 2],
    description: 'ids of skillsetWantToMaster onboarding',
  })
  @IsOptional()
  @IsNumber({}, { each: true })
  skillsetWantToMaster: number[];

  @IsArray()
  @ApiPropertyOptional({
    type: [Number],
    required: false,
    example: [1, 2],
    description: 'id of strugglesWhenSpeaking onboarding',
  })
  @IsOptional()
  @IsNumber({}, { each: true })
  learningStruggles: number[];
}
