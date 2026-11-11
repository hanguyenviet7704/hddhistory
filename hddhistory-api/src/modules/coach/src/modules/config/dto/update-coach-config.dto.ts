import { ApiPropertyOptional } from '@nestjs/swagger';
import { Type } from 'class-transformer';
import {
  IsArray,
  IsBoolean,
  IsInt,
  IsOptional,
  IsString,
  Max,
  Min,
  ValidateNested
} from 'class-validator';

export class CoachHotlineDto {
  @ApiPropertyOptional({ example: 'vi' })
  @IsString()
  locale: string;

  @ApiPropertyOptional({
    example: 'VN',
    description:
      'ISO country code. Omit for the locale-wide fallback — a Vietnamese speaker abroad still needs a number.',
  })
  @IsOptional()
  @IsString()
  country?: string;

  @ApiPropertyOptional({ example: 'Đường dây nóng Ngày mai' })
  @IsString()
  label: string;

  @ApiPropertyOptional({ example: '096 306 1414' })
  @IsString()
  number: string;
}

export class UpdateCoachConfigDto {
  @ApiPropertyOptional({
    description:
      'Master switch. Off means the bubble never appears and the session endpoints refuse.',
  })
  @IsOptional()
  @IsBoolean()
  enabled?: boolean;

  @ApiPropertyOptional({ type: [CoachHotlineDto] })
  @IsOptional()
  @IsArray()
  @ValidateNested({ each: true })
  @Type(() => CoachHotlineDto)
  hotlines?: CoachHotlineDto[];

  @ApiPropertyOptional({
    example: 'gemini-flash-latest',
    description:
      'Gemini model for the Coach conversational calls. Empty string clears the override (falls back to the GEMINI_MODEL env).',
  })
  @IsOptional()
  @IsString()
  geminiModel?: string;

  @ApiPropertyOptional({
    example: 'gemini-flash-latest',
    description:
      'Model for scene WRITING only (once per practice, heaviest prompt). Empty = geminiModel, then the GEMINI_SCENE_MODEL env.',
  })
  @IsOptional()
  @IsString()
  geminiSceneModel?: string;

  @ApiPropertyOptional({
    example: 'gemini-flash-latest,gemini-flash-lite-latest',
    description:
      'Models a call falls back to, best first, when its own answers 429/503. Empty = the GEMINI_FALLBACK_MODELS env, then the built-in pair. "off" disables the fallback.',
  })
  @IsOptional()
  @IsString()
  geminiFallbackModels?: string;

  @ApiPropertyOptional({ description: 'Luồng 1 — ask "học kiểu nào dễ vào nhất?" during onboarding.' })
  @IsOptional()
  @IsBoolean()
  onboardAskStyle?: boolean;

  @ApiPropertyOptional({ description: 'Luồng 1 — ask the age band during onboarding.' })
  @IsOptional()
  @IsBoolean()
  onboardAskAge?: boolean;

  @ApiPropertyOptional({ description: 'Luồng 1 — ask the gender during onboarding.' })
  @IsOptional()
  @IsBoolean()
  onboardAskGender?: boolean;

  @ApiPropertyOptional({ description: 'Luồng 1 — ask the occupation during onboarding.' })
  @IsOptional()
  @IsBoolean()
  onboardAskJob?: boolean;

  @ApiPropertyOptional({
    example: 4,
    description:
      'Luồng 2 — follow-up questions allowed after the grading turn. Each one is a Gemini call; 0 closes the floor.',
  })
  @IsOptional()
  @IsInt()
  @Min(0)
  @Max(10)
  talkFreeMaxTurns?: number;

  @ApiPropertyOptional({
    description: 'Luồng 6 — master switch for the rating sheet after ⟨Vẫn đóng⟩.',
  })
  @IsOptional()
  @IsBoolean()
  ratingAskEnabled?: boolean;

  @ApiPropertyOptional({
    example: 7,
    description: 'Days before a reader who ANSWERED is asked again. 0 turns the wait off.',
  })
  @IsOptional()
  @IsInt()
  @Min(0)
  @Max(365)
  ratingAskMinDays?: number;

  @ApiPropertyOptional({
    example: 3,
    description: 'Days before a reader who chose ⟨Để sau⟩ is asked again. 0 turns the wait off.',
  })
  @IsOptional()
  @IsInt()
  @Min(0)
  @Max(365)
  ratingAskSnoozeDays?: number;

  @ApiPropertyOptional({
    example: 1,
    description: 'Ask on every Nth exit. 1 means every exit.',
  })
  @IsOptional()
  @IsInt()
  @Min(1)
  @Max(50)
  ratingAskEveryNthExit?: number;

  @ApiPropertyOptional({
    example: 100,
    description: 'Percentage of otherwise-eligible exits that get asked. 100 asks them all.',
  })
  @IsOptional()
  @IsInt()
  @Min(0)
  @Max(100)
  ratingAskProbability?: number;

  @ApiPropertyOptional({
    example: 0,
    description: 'Asks per reader before the question retires for good. 0 means no ceiling.',
  })
  @IsOptional()
  @IsInt()
  @Min(0)
  @Max(100)
  ratingAskMaxPerUser?: number;
}
