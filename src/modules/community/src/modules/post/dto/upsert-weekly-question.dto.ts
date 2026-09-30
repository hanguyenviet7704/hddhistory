import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { Type } from 'class-transformer';
import {
  IsDate,
  IsInt,
  IsNotEmpty,
  IsOptional,
  Max,
  Min,
  ValidateNested,
} from 'class-validator';

import { TranslationDto } from '@utils/dto/common.dto';

// The weekly question is a post with type WEEKLY_QUESTION: the team authors it
// in all five languages, so it carries translations instead of a body and is
// shown to every reader regardless of locale.
export class UpsertWeeklyQuestionDto {
  @ApiProperty({ type: TranslationDto })
  @IsNotEmpty()
  @ValidateNested()
  @Type(() => TranslationDto)
  title: TranslationDto;

  @ApiPropertyOptional({
    type: TranslationDto,
    description: 'The guidance line under the question',
  })
  @IsOptional()
  @ValidateNested()
  @Type(() => TranslationDto)
  note?: TranslationDto;

  @ApiProperty({ example: 34 })
  @IsInt()
  @Min(1)
  @Max(53)
  @Type(() => Number)
  weekNumber: number;

  @ApiProperty({ example: 2026 })
  @IsInt()
  @Min(2020)
  @Type(() => Number)
  year: number;

  @ApiProperty()
  @IsDate()
  @Type(() => Date)
  startsAt: Date;

  @ApiProperty()
  @IsDate()
  @Type(() => Date)
  endsAt: Date;
}
