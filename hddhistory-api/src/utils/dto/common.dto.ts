import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import {
  IsBoolean,
  IsNotEmpty,
  IsNumber,
  IsObject,
  IsOptional,
  IsString,
} from 'class-validator';

import { IsMultiLangString } from './multi-languge';

export class TranslationDto {
  @ApiPropertyOptional()
  @IsString()
  @IsOptional()
  en?: string;

  @ApiPropertyOptional()
  @IsString()
  @IsOptional()
  vi?: string;

  @ApiPropertyOptional()
  @IsString()
  @IsOptional()
  zh?: string;

  @ApiPropertyOptional()
  @IsString()
  @IsOptional()
  ja?: string;

  @ApiPropertyOptional()
  @IsString()
  @IsOptional()
  ko?: string;
}

export class PriceDto {
  @ApiProperty({ example: 'USD', required: true })
  @IsString()
  @IsNotEmpty()
  currency: string;

  @ApiProperty({ required: true, example: 100 })
  @IsNumber()
  @IsNotEmpty()
  originalPrice: number;

  @ApiPropertyOptional({ required: true, example: 80 })
  @IsNumber()
  @IsOptional()
  salePrice: number;

  @ApiPropertyOptional({ example: false, required: false })
  @IsBoolean()
  @IsOptional()
  isFree: boolean;
}

export class LabelDto {
  @ApiProperty({ required: true, example: 1 })
  @IsNotEmpty()
  @IsNumber()
  id: number;

  @ApiPropertyOptional({
    required: false,
    example: 'https://www.example.com',
  })
  @IsOptional()
  @IsString()
  icon: string;

  @ApiPropertyOptional({
    type: Object,
    required: false,
    example: { en: 'title', vi: 'title' },
  })
  @IsObject()
  @IsOptional()
  @IsMultiLangString()
  title: Record<string, string>;

  @ApiPropertyOptional({
    type: Object,
    required: false,
    example: { en: 'label', vi: 'label' },
  })
  @IsObject()
  @IsOptional()
  @IsMultiLangString()
  label: Record<string, string>;

  @ApiPropertyOptional({
    required: false,
    example: 'track_12345',
  })
  @IsOptional()
  @IsString()
  trackingLabel: string;
}
