import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { IsMongoId, IsOptional, IsString, MaxLength } from 'class-validator';

export class ApproveCommunityRoomSuggestionDto {
  @ApiProperty({
    description:
      'The topic that was opened for this ask. Created first in the Topics screen, then linked here — approving does not invent a room, it points at one, because a room needs a name in all five languages and a slug that a free-text suggestion does not have.',
  })
  @IsMongoId()
  topicId: string;

  @ApiPropertyOptional({ maxLength: 500 })
  @IsOptional()
  @IsString()
  @MaxLength(500)
  note?: string;
}

export class DeclineCommunityRoomSuggestionDto {
  @ApiPropertyOptional({ maxLength: 500 })
  @IsOptional()
  @IsString()
  @MaxLength(500)
  note?: string;
}
