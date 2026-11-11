import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import {
  IsEnum,
  IsIn,
  IsNotEmpty,
  IsOptional,
  IsString,
  MaxLength,
} from 'class-validator';

import { ImportSourceType } from '../enum/learning-import.enum';

// The locales the app ships. Generating into a locale the UI cannot render would
// produce a lesson the user can read but an app that labels it wrongly.
export const SUPPORTED_OUTPUT_LOCALES = ['en', 'vi', 'zh', 'ja', 'ko'] as const;

export class CreateLearningImportDto {
  @ApiProperty({
    enum: ImportSourceType,
    description:
      'Where the material comes from. `pdf` requires `fileKey`; `youtube` requires `url`.',
    example: ImportSourceType.PDF,
  })
  @IsEnum(ImportSourceType)
  sourceType: ImportSourceType;

  @ApiPropertyOptional({
    description:
      'R2 object key of a PDF already uploaded via POST /cloudflares/upload. Required when sourceType is `pdf`.',
    example: 'user_import/pdf_1754800000000_grammar.pdf',
  })
  @IsOptional()
  @IsString()
  @IsNotEmpty()
  fileKey?: string;

  @ApiPropertyOptional({
    description: "Original filename, shown on the lesson card. Display only.",
    example: 'Giao trinh A2.pdf',
  })
  @IsOptional()
  @IsString()
  @MaxLength(255)
  fileName?: string;

  @ApiPropertyOptional({
    description: 'YouTube video URL. Required when sourceType is `youtube`.',
    example: 'https://www.youtube.com/watch?v=dQw4w9WgXcQ',
  })
  @IsOptional()
  @IsString()
  @IsNotEmpty()
  url?: string;

  @ApiProperty({
    description:
      'Language the lesson is written in, regardless of the source language.',
    enum: SUPPORTED_OUTPUT_LOCALES,
    example: 'vi',
  })
  @IsIn(SUPPORTED_OUTPUT_LOCALES as unknown as string[])
  outputLocale: string;
}
