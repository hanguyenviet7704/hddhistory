import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { Type } from 'class-transformer';
import {
  ArrayMaxSize,
  ArrayMinSize,
  IsArray,
  IsEnum,
  IsInt,
  IsMongoId,
  IsOptional,
  IsString,
  Max,
  MaxLength,
  Min,
  ValidateNested,
} from 'class-validator';

import {
  SITUATION_MAX_BEATS,
  SITUATION_MAX_LEVEL,
  SITUATION_MIN_LEVEL,
} from '../../../shared/coach.constant';
import {
  CoachSituationContextGroup,
  CoachSituationVariant,
} from '../enum/situation.enum';

/**
 * One named approach offered under a scene's question.
 *
 * `key` is accepted but never trusted: the service re-stamps A·B·C from
 * position, so an editor who deletes the middle row cannot leave "A" and "C"
 * on screen with nothing between them.
 */
export class CoachSituationOptionDto {
  @ApiPropertyOptional({ description: '"A" · "B" · "C". Re-stamped from position on save.' })
  @IsOptional()
  @IsString()
  @MaxLength(2)
  key?: string;

  @ApiProperty({ description: "The approach's name, 2-4 words." })
  @IsString()
  @MaxLength(40)
  label: string;

  @ApiProperty({ description: "A short line in that approach's voice — never a finished answer." })
  @IsString()
  @MaxLength(120)
  text: string;
}

export class GetCoachSituationsDto {
  @ApiPropertyOptional()
  @IsOptional()
  @IsMongoId()
  habitId?: string;

  @ApiPropertyOptional({ example: 'vi' })
  @IsOptional()
  @IsString()
  locale?: string;

  @ApiPropertyOptional({ enum: CoachSituationVariant })
  @IsOptional()
  @IsEnum(CoachSituationVariant)
  variant?: CoachSituationVariant;
}

export class UpdateCoachSituationDto {
  @ApiPropertyOptional({
    description:
      'The rewritten scene. Saving marks the row EDITED, which stops generation from ever overwriting it.',
  })
  @IsString()
  @MaxLength(1000)
  prompt: string;

  @ApiPropertyOptional({
    type: [String],
    description: 'Two tappable opener suggestions for the scene.',
  })
  @IsOptional()
  @IsArray()
  @IsString({ each: true })
  @ArrayMaxSize(3)
  samples?: string[];

  @ApiPropertyOptional({
    enum: CoachSituationContextGroup,
    description:
      "Which corner of life the scene is set in. Selection prefers the reader's own group, then trung_tinh.",
  })
  @IsOptional()
  @IsEnum(CoachSituationContextGroup)
  contextGroup?: CoachSituationContextGroup;

  @ApiPropertyOptional({
    description:
      'The SAME scene told about somebody else ("Có một người đang ở cuộc họp…"), shown on a low-mood day. Same scene, same id — only the telling changes.',
  })
  @IsOptional()
  @IsString()
  @MaxLength(1000)
  promptThirdPerson?: string;
  @ApiPropertyOptional({
    description:
      'Nhịp 4 — the scene\'s SECOND stage: the other person reacts, the situation turns one notch harder, and it ends in a question again. Same people, same place.',
  })
  @IsOptional()
  @IsString()
  @MaxLength(1000)
  promptStage2?: string;

  @ApiPropertyOptional({
    description: 'The second stage told about somebody else, for a low-mood day.',
  })
  @IsOptional()
  @IsString()
  @MaxLength(1000)
  promptStage2ThirdPerson?: string;


  @ApiPropertyOptional({
    type: [String],
    description:
      'The scene script: 2–4 ordered probe intents the Coach walks after the first answer.',
  })
  @IsOptional()
  @IsArray()
  @IsString({ each: true })
  @ArrayMaxSize(SITUATION_MAX_BEATS)
  beats?: string[];

  @ApiPropertyOptional({
    type: [String],
    description:
      "The other person's line at each beat, index-aligned with `beats`. Empty entry = probe rather than perform.",
  })
  @IsOptional()
  @IsArray()
  @IsString({ each: true })
  @ArrayMaxSize(SITUATION_MAX_BEATS)
  beatLines?: string[];

  @ApiPropertyOptional({ description: 'Who those lines belong to, e.g. "Linh".' })
  @IsOptional()
  @IsString()
  @MaxLength(60)
  counterpart?: string;

  @ApiPropertyOptional({ minimum: 1, maximum: 5, description: 'Difficulty band 1–5.' })
  @IsOptional()
  @Type(() => Number)
  @IsInt()
  @Min(SITUATION_MIN_LEVEL)
  @Max(SITUATION_MAX_LEVEL)
  level?: number;

  @ApiPropertyOptional({
    description: 'The lesson this scene lands, in one sentence.',
  })
  @IsOptional()
  @IsString()
  @MaxLength(300)
  takeaway?: string;

  @ApiPropertyOptional({
    description: 'The concrete move this scene teaches — the reminder pre-fill.',
  })
  @IsOptional()
  @IsString()
  @MaxLength(120)
  goodMove?: string;

  @ApiPropertyOptional({
    type: [CoachSituationOptionDto],
    description:
      'The three named ways to answer stage one, shown as TEXT under the question — never as pills. Send the whole trio or omit it; `key` is re-stamped A·B·C from position, so the form need not send it.',
  })
  @IsOptional()
  @IsArray()
  @ArrayMaxSize(3)
  @ValidateNested({ each: true })
  @Type(() => CoachSituationOptionDto)
  openingOptions?: CoachSituationOptionDto[];
}

export class ImportCoachSituationItemDto {
  @ApiProperty({ description: 'Library habit id this scene belongs to.' })
  @IsMongoId()
  habitId: string;

  @ApiProperty({ example: 'vi' })
  @IsString()
  locale: string;

  @ApiPropertyOptional({ enum: CoachSituationVariant, default: 'default' })
  @IsOptional()
  @IsEnum(CoachSituationVariant)
  variant?: CoachSituationVariant;

  @ApiPropertyOptional({ default: 'unknown' })
  @IsOptional()
  @IsString()
  audience?: string;

  @ApiPropertyOptional({ default: 'unknown' })
  @IsOptional()
  @IsString()
  goalKey?: string;

  @ApiProperty({ description: 'Scene + closing question, one block of prose.' })
  @IsString()
  @MaxLength(1000)
  prompt: string;

  @ApiPropertyOptional({ type: [String] })
  @IsOptional()
  @IsArray()
  @IsString({ each: true })
  @ArrayMaxSize(3)
  samples?: string[];

  @ApiPropertyOptional({
    type: [CoachSituationOptionDto],
    description:
      'The three named ways to answer stage one, shown as TEXT under the question — never as pills. Send the whole trio or omit it; `key` is re-stamped A·B·C from position, so the form need not send it.',
  })
  @IsOptional()
  @IsArray()
  @ArrayMaxSize(3)
  @ValidateNested({ each: true })
  @Type(() => CoachSituationOptionDto)
  openingOptions?: CoachSituationOptionDto[];

  @ApiPropertyOptional({
    enum: CoachSituationContextGroup,
    description:
      "Which corner of life the scene is set in. Selection prefers the reader's own group, then trung_tinh.",
  })
  @IsOptional()
  @IsEnum(CoachSituationContextGroup)
  contextGroup?: CoachSituationContextGroup;

  @ApiPropertyOptional({
    description:
      'The SAME scene told about somebody else ("Có một người đang ở cuộc họp…"), shown on a low-mood day. Same scene, same id — only the telling changes.',
  })
  @IsOptional()
  @IsString()
  @MaxLength(1000)
  promptThirdPerson?: string;
  @ApiPropertyOptional({
    description:
      'Nhịp 4 — the scene\'s SECOND stage: the other person reacts, the situation turns one notch harder, and it ends in a question again. Same people, same place.',
  })
  @IsOptional()
  @IsString()
  @MaxLength(1000)
  promptStage2?: string;

  @ApiPropertyOptional({
    description: 'The second stage told about somebody else, for a low-mood day.',
  })
  @IsOptional()
  @IsString()
  @MaxLength(1000)
  promptStage2ThirdPerson?: string;


  @ApiPropertyOptional({ type: [String], description: '2–4 probe intents.' })
  @IsOptional()
  @IsArray()
  @IsString({ each: true })
  @ArrayMaxSize(SITUATION_MAX_BEATS)
  beats?: string[];

  @ApiPropertyOptional({
    type: [String],
    description:
      "What the OTHER person says at each beat, index-aligned with `beats`. An empty entry means probe rather than perform.",
  })
  @IsOptional()
  @IsArray()
  @IsString({ each: true })
  @ArrayMaxSize(SITUATION_MAX_BEATS)
  beatLines?: string[];

  @ApiPropertyOptional({ description: 'Who those lines belong to, e.g. "Linh".' })
  @IsOptional()
  @IsString()
  @MaxLength(60)
  counterpart?: string;

  @ApiPropertyOptional({ minimum: 1, maximum: 5, description: 'Difficulty band.' })
  @IsOptional()
  @Type(() => Number)
  @IsInt()
  @Min(SITUATION_MIN_LEVEL)
  @Max(SITUATION_MAX_LEVEL)
  level?: number;

  @ApiPropertyOptional()
  @IsOptional()
  @IsString()
  @MaxLength(300)
  takeaway?: string;

  @ApiPropertyOptional()
  @IsOptional()
  @IsString()
  @MaxLength(120)
  goodMove?: string;
}

export class ImportCoachSituationsDto {
  @ApiProperty({ type: [ImportCoachSituationItemDto] })
  @IsArray()
  @ArrayMinSize(1)
  @ArrayMaxSize(2000)
  @ValidateNested({ each: true })
  @Type(() => ImportCoachSituationItemDto)
  items: ImportCoachSituationItemDto[];
}
