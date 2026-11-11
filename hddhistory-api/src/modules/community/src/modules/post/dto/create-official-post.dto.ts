import { ApiPropertyOptional } from '@nestjs/swagger';
import { IsBoolean, IsIn, IsNotEmpty, IsOptional, IsString } from 'class-validator';

import { CreateCommunityPostDto } from './create-community-post.dto';
import { COMMUNITY_LOCALES } from '../../../interface/community.interface';

// A team post is written for one locale's feed at a time, so the admin has to
// say which. Everything else matches an ordinary post.
export class CreateOfficialPostDto extends CreateCommunityPostDto {
  @ApiPropertyOptional({ enum: COMMUNITY_LOCALES })
  @IsNotEmpty()
  @IsString()
  @IsIn(COMMUNITY_LOCALES as unknown as string[])
  locale: string;

  @ApiPropertyOptional({ default: false })
  @IsOptional()
  @IsBoolean()
  isPinned?: boolean;
}
