import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { IsMongoId, IsNotEmpty, IsOptional, IsString, MaxLength } from 'class-validator';

export const COMMUNITY_COMMENT_MAX_LENGTH = 2000;

export class CreateCommunityCommentDto {
  @ApiProperty({ maxLength: COMMUNITY_COMMENT_MAX_LENGTH })
  @IsNotEmpty()
  @IsString()
  @MaxLength(COMMUNITY_COMMENT_MAX_LENGTH)
  body: string;

  @ApiPropertyOptional({
    description:
      'Top-level comment being replied to. Replying to a reply still passes the top-level id — the thread is two levels deep, never more.',
  })
  @IsOptional()
  @IsMongoId()
  parentId?: string;

  @ApiPropertyOptional({
    description: 'Author of the reply being answered, for the "@name" prefix',
  })
  @IsOptional()
  @IsMongoId()
  replyToUserId?: string;
}
