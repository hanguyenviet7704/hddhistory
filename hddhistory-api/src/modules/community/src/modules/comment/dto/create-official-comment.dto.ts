import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { IsMongoId, IsNotEmpty, IsOptional, IsString, MaxLength } from 'class-validator';

/**
 * A comment written by the team from the panel.
 *
 * Same shape as a reader's comment minus `replyToUserId`: that field carries the
 * "@name" a reader taps to answer one person inside a thread, and the panel has
 * no such gesture — a team answer is addressed to the thread.
 */
export class CreateOfficialCommentDto {
  @ApiProperty()
  @IsString()
  @IsNotEmpty()
  @MaxLength(4000)
  body: string;

  @ApiPropertyOptional({
    description: 'Reply INSIDE a thread — the top-level comment being answered.',
  })
  @IsOptional()
  @IsMongoId()
  parentId?: string;
}
