import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { IsArray, IsIn, IsOptional, IsString } from 'class-validator';

import {
  COMMUNITY_LOCALES,
  CommunityLocale,
} from '../../../interface/community.interface';

export class UpsertCommunityChatGuideDto {
  @ApiProperty({ enum: COMMUNITY_LOCALES })
  @IsIn(COMMUNITY_LOCALES as unknown as string[])
  locale: CommunityLocale;

  @ApiPropertyOptional()
  @IsOptional()
  @IsString()
  title?: string;

  @ApiPropertyOptional()
  @IsOptional()
  @IsString()
  intro?: string;

  @ApiPropertyOptional({ type: [String] })
  @IsOptional()
  @IsArray()
  @IsString({ each: true })
  dos?: string[];

  @ApiPropertyOptional({ type: [String] })
  @IsOptional()
  @IsArray()
  @IsString({ each: true })
  donts?: string[];

  @ApiPropertyOptional({ type: [String] })
  @IsOptional()
  @IsArray()
  @IsString({ each: true })
  starters?: string[];
}
