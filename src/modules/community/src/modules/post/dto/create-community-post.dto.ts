import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { Type } from 'class-transformer';
import {
  ArrayMaxSize,
  IsArray,
  IsBoolean,
  IsMongoId,
  IsNotEmpty,
  IsOptional,
  IsString,
  MaxLength,
  ValidateNested,
} from 'class-validator';

import { ToBoolean } from '@utils/boolean.utils';

export const COMMUNITY_POST_MAX_LENGTH = 5000;
export const COMMUNITY_POST_MAX_SUBJECT_LENGTH = 160;
export const COMMUNITY_POST_MAX_IMAGES = 4;
export const COMMUNITY_CARD_MAX_TITLE_LENGTH = 300;
export const COMMUNITY_CARD_MAX_BACK_LENGTH = 1000;

// The keypoint card as the composer snapshots it. Text comes from the client
// because the card it shows is the one the reader picked in their own library;
// it is length-capped here so a crafted request cannot store an essay.
export class CommunityAttachedCardDto {
  @ApiProperty()
  @IsMongoId()
  keypointId: string;

  @ApiProperty({ maxLength: COMMUNITY_CARD_MAX_TITLE_LENGTH })
  @IsNotEmpty()
  @IsString()
  @MaxLength(COMMUNITY_CARD_MAX_TITLE_LENGTH)
  title: string;

  @ApiProperty({ maxLength: COMMUNITY_CARD_MAX_BACK_LENGTH })
  @IsString()
  @MaxLength(COMMUNITY_CARD_MAX_BACK_LENGTH)
  back: string;

  @ApiPropertyOptional()
  @IsOptional()
  @IsString()
  @MaxLength(COMMUNITY_CARD_MAX_TITLE_LENGTH)
  courseName?: string;
}

export class CreateCommunityPostDto {
  @ApiPropertyOptional({
    maxLength: COMMUNITY_POST_MAX_SUBJECT_LENGTH,
    description: 'Headline above the story',
  })
  @IsOptional()
  @IsString()
  @MaxLength(COMMUNITY_POST_MAX_SUBJECT_LENGTH)
  subject?: string;

  @ApiProperty({ maxLength: COMMUNITY_POST_MAX_LENGTH })
  @IsNotEmpty()
  @IsString()
  @MaxLength(COMMUNITY_POST_MAX_LENGTH)
  body: string;

  @ApiPropertyOptional({ description: 'Omit to post without a group' })
  @IsOptional()
  @IsMongoId()
  topicId?: string;

  @ApiPropertyOptional({ type: [String], maxItems: COMMUNITY_POST_MAX_IMAGES })
  @IsOptional()
  @IsArray()
  @ArrayMaxSize(COMMUNITY_POST_MAX_IMAGES)
  @IsString({ each: true })
  images?: string[];

  @ApiPropertyOptional({ description: 'Course whose roadmap is attached to the post' })
  @IsOptional()
  @IsMongoId()
  attachedCourseId?: string;

  @ApiPropertyOptional({ type: CommunityAttachedCardDto })
  @IsOptional()
  @ValidateNested()
  @Type(() => CommunityAttachedCardDto)
  attachedCard?: CommunityAttachedCardDto;

  @ApiPropertyOptional({
    type: Boolean,
    description: 'Hide the writer name from readers. Moderation still sees it.',
  })
  @IsOptional()
  @IsBoolean()
  @ToBoolean()
  isAnonymous?: boolean;
}
