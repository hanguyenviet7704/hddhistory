import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { IsMongoId, IsNotEmpty, IsOptional, IsString, MaxLength } from 'class-validator';

// Shorter than a post's body on purpose: this is a chat line, and the design's
// bubble tops out around three lines before it stops reading as one.
export const COMMUNITY_CHAT_MAX_LENGTH = 1000;

export class SendCommunityChatDto {
  @ApiProperty({ maxLength: COMMUNITY_CHAT_MAX_LENGTH })
  @IsNotEmpty()
  @IsString()
  @MaxLength(COMMUNITY_CHAT_MAX_LENGTH)
  body: string;

  /**
   * The line being answered.
   *
   * Flat, not a thread: a reply points at one message and the room stays a
   * single stream. Nesting a chat is how it stops being readable at a glance,
   * and the design draws a quote strip, not an indent.
   */
  @ApiPropertyOptional()
  @IsOptional()
  @IsMongoId()
  replyToId?: string;
}
