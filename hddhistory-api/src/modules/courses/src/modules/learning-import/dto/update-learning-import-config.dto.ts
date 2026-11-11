import { ApiPropertyOptional } from '@nestjs/swagger';
import {
  ArrayMaxSize,
  IsArray,
  IsBoolean,
  IsOptional,
  IsString,
  IsUrl,
  MaxLength,
} from 'class-validator';

export class UpdateLearningImportConfigDto {
  @ApiPropertyOptional({
    description:
      'Whether users may start a new import. Off closes the create endpoint only — existing lessons stay readable and running jobs finish.',
  })
  @IsOptional()
  @IsBoolean()
  enabled?: boolean;

  @ApiPropertyOptional({
    description:
      'Optional sentence shown to the user while the feature is off. Empty falls back to the app\'s own localized line.',
  })
  @IsOptional()
  @IsString()
  @MaxLength(300)
  disabledNote?: string;

  @ApiPropertyOptional({
    description:
      'The whole LESSON-cover pool, replaced as a list (the panel edits it as one). Urls of images already uploaded to R2. Lessons already dealt a cover keep it whatever happens here.',
    type: [String],
  })
  @IsOptional()
  @IsArray()
  @ArrayMaxSize(200)
  @IsUrl({ require_protocol: true }, { each: true })
  courseCoverUrls?: string[];

  @ApiPropertyOptional({
    description:
      'The whole KEYPOINT-thumbnail pool, replaced as a list. Separate from the lesson covers on purpose — different kind of picture.',
    type: [String],
  })
  @IsOptional()
  @IsArray()
  @ArrayMaxSize(200)
  @IsUrl({ require_protocol: true }, { each: true })
  keypointImageUrls?: string[];
}
