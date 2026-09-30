import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import {
  IsBoolean,
  IsEnum,
  IsNotEmpty,
  IsOptional,
  IsString,
  Matches,
  MaxLength,
} from 'class-validator';

import { CommunityContentStatus } from '../../../enum/community.enum';

/**
 * Opens a chat room, or edits the one already on that slug.
 *
 * Keyed by SLUG rather than by id because the slug is what the app opens the
 * room with — `hoi-ban-tron` is compiled into the client, so the row it points
 * at has to be reachable by that name and re-runnable without making a second
 * room every time someone presses the button.
 */
export class UpsertCommunityChatRoomDto {
  @ApiProperty({ example: 'hoi-ban-tron' })
  @IsString()
  @IsNotEmpty()
  @MaxLength(60)
  // Lowercase, digits and dashes: the slug travels in a URL and is typed into
  // the client by hand, so anything that needs escaping is a slug that will be
  // got wrong.
  @Matches(/^[a-z0-9]+(?:-[a-z0-9]+)*$/, {
    message: 'slug must be lowercase words separated by single dashes',
  })
  slug: string;

  @ApiProperty({ example: 'Hội bàn tròn' })
  @IsString()
  @IsNotEmpty()
  @MaxLength(80)
  name: string;

  @ApiPropertyOptional({ default: true })
  @IsOptional()
  @IsBoolean()
  isOfficial?: boolean;

  @ApiPropertyOptional({ enum: CommunityContentStatus })
  @IsOptional()
  @IsEnum(CommunityContentStatus)
  status?: CommunityContentStatus;
}
