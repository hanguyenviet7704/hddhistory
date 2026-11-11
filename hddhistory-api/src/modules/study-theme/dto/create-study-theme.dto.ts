import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import {
  IsArray,
  IsBoolean,
  IsEnum,
  IsHexColor,
  IsNotEmpty,
  IsNumber,
  IsOptional,
  IsString,
  Matches,
} from 'class-validator';

import { StudyThemeMode } from '../enum/study-theme.enum';

export class CreateStudyThemeDto {
  @ApiProperty({
    description: 'Stable unique slug for the preset',
    example: 'lavender',
  })
  @IsString()
  @IsNotEmpty()
  key: string;

  @ApiProperty({ enum: StudyThemeMode, example: StudyThemeMode.COLOR })
  @IsEnum(StudyThemeMode)
  mode: StudyThemeMode;

  @ApiProperty({
    description: 'Group heading shown in the picker',
    example: 'Solid & Gradient',
  })
  @IsString()
  @IsNotEmpty()
  category: string;

  @ApiProperty({ example: 'Lavender' })
  @IsString()
  @IsNotEmpty()
  name: string;

  @ApiPropertyOptional({
    type: [String],
    description:
      'Hex colours for `color` mode. 1 = solid, 2+ = top->bottom gradient. Empty for non-color modes.',
    example: ['#EDE9FF', '#D5D2F7'],
    default: [],
  })
  @IsOptional()
  @IsArray()
  @IsHexColor({ each: true })
  gradient?: string[] = [];

  @ApiPropertyOptional({
    description: 'R2/CDN URL for `image` mode',
    example: 'https://cdn.meup.training/study-themes/forest.jpg',
  })
  @IsOptional()
  @IsString()
  imageUrl?: string;

  @ApiPropertyOptional({
    description: 'Video URL for `video` (live) mode',
    example: 'https://cdn.meup.training/study-themes/rain.mp4',
  })
  @IsOptional()
  @IsString()
  videoUrl?: string;

  @ApiPropertyOptional({
    description: 'Ambient audio for live presets',
    example: 'https://cdn.meup.training/study-themes/rain.mp3',
  })
  @IsOptional()
  @IsString()
  audioUrl?: string;

  @ApiPropertyOptional({
    description:
      'Optional picker thumbnail (video presets need a poster; else derive on client)',
    example: 'https://cdn.meup.training/study-themes/rain-thumb.jpg',
  })
  @IsOptional()
  @IsString()
  thumbUrl?: string;

  @ApiPropertyOptional({
    description:
      'Readability overlay colour as 8-digit hex #RRGGBBAA, omit for none',
    example: '#00000059',
  })
  @IsOptional()
  @Matches(/^#[0-9A-Fa-f]{8}$/, {
    message: 'overlay must be an 8-digit hex color (#RRGGBBAA)',
  })
  overlay?: string;

  @ApiPropertyOptional({
    description: 'Whether the background reads dark',
    default: false,
  })
  @IsOptional()
  @IsBoolean()
  isDark?: boolean = false;

  @ApiPropertyOptional({
    description: 'Ascending sort order within the whole list',
    default: 0,
  })
  @IsOptional()
  @IsNumber()
  order?: number = 0;

  @ApiPropertyOptional({
    description: 'Inactive presets are hidden from the public endpoint',
    default: true,
  })
  @IsOptional()
  @IsBoolean()
  isActive?: boolean = true;

  @ApiPropertyOptional({
    description: 'Premium-only preset (locked behind the paywall in-app, hidden in onboarding)',
    default: false,
  })
  @IsOptional()
  @IsBoolean()
  isPremium?: boolean = false;
}
