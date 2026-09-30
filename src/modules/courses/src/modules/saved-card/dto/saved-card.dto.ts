import {
  ApiProperty,
  ApiPropertyOptional,
  IntersectionType,
} from '@nestjs/swagger';
import { Type } from 'class-transformer';
import {
  IsNotEmpty,
  IsObject,
  IsOptional,
  IsString,
  MaxLength,
  ValidateNested,
} from 'class-validator';

import { TranslationDto } from '@utils/dto/common.dto';
import { PageOptionsDto } from '@utils/dto/paging/page.dto';

export class SaveCardDto {
  @ApiProperty()
  @IsNotEmpty()
  @IsString()
  @MaxLength(64)
  keypointId: string;

  @ApiPropertyOptional()
  @IsOptional()
  @IsString()
  @MaxLength(64)
  lessonId?: string;

  @ApiPropertyOptional()
  @IsOptional()
  @IsString()
  @MaxLength(64)
  courseId?: string;

  /**
   * The recap in EVERY language the client had, not just the one on screen.
   *
   * The card's back face is a snapshot (the recap is derived client-side, see
   * the schema), and a snapshot of one language is a card that stops following
   * the reader: saved in Vietnamese, app switched to English, and the Library
   * shows an English title over a Vietnamese body — reported on-device
   * 2026-09-10. The client already holds all five, so it sends all five.
   */
  @ApiPropertyOptional({ type: TranslationDto })
  @IsOptional()
  @IsObject()
  @ValidateNested()
  @Type(() => TranslationDto)
  recap?: TranslationDto;

  // The recap the reader saw. Bounded well above any authored takeaway so a
  // long one is never silently clipped, but not unbounded — this is free text
  // arriving from the client.
  //
  // Kept alongside `recap` for app builds that predate it; those still save,
  // still single-language, exactly as before.
  @ApiPropertyOptional()
  @IsOptional()
  @IsString()
  @MaxLength(8000)
  recapText?: string;
}

export class GetSavedCardsDto extends IntersectionType(PageOptionsDto) {}
