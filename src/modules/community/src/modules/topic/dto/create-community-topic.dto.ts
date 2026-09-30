import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { Type } from 'class-transformer';
import {
  IsBoolean,
  IsNotEmpty,
  IsNumber,
  IsOptional,
  IsString,
  Matches,
  ValidateNested,
} from 'class-validator';

import { TranslationDto } from '@utils/dto/common.dto';

export class CreateCommunityTopicDto {
  @ApiProperty({ type: TranslationDto })
  @IsNotEmpty()
  @ValidateNested()
  @Type(() => TranslationDto)
  name: TranslationDto;

  @ApiPropertyOptional({ type: TranslationDto })
  @IsOptional()
  @ValidateNested()
  @Type(() => TranslationDto)
  description?: TranslationDto;

  @ApiProperty({ example: 'ky-luat-thoi-quen' })
  @IsNotEmpty()
  @IsString()
  @Matches(/^[a-z0-9-]+$/, {
    message: 'slug must contain only lowercase letters, digits and dashes',
  })
  slug: string;

  @ApiPropertyOptional()
  @IsOptional()
  @IsString()
  imageUrl?: string;

  @ApiPropertyOptional({ default: 0 })
  @IsOptional()
  @IsNumber()
  @Type(() => Number)
  sortOrder?: number;

  @ApiPropertyOptional({ default: true })
  @IsOptional()
  @IsBoolean()
  isActive?: boolean;
}
