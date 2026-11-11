import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { IsNotEmpty, IsOptional, IsString, MaxLength } from 'class-validator';

// The design's counters: 40 for the name, 160 for the description. Enforced
// here as well as in the form — the form is a courtesy, this is the contract.
export const ROOM_SUGGESTION_MAX_NAME_LENGTH = 40;
export const ROOM_SUGGESTION_MAX_DESCRIPTION_LENGTH = 160;

export class CreateCommunityRoomSuggestionDto {
  @ApiProperty({ maxLength: ROOM_SUGGESTION_MAX_NAME_LENGTH })
  @IsNotEmpty()
  @IsString()
  @MaxLength(ROOM_SUGGESTION_MAX_NAME_LENGTH)
  name: string;

  @ApiPropertyOptional({ maxLength: ROOM_SUGGESTION_MAX_DESCRIPTION_LENGTH })
  @IsOptional()
  @IsString()
  @MaxLength(ROOM_SUGGESTION_MAX_DESCRIPTION_LENGTH)
  description?: string;
}
