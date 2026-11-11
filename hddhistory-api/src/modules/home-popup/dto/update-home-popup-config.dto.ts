import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { Type } from 'class-transformer';
import {
  ArrayMaxSize,
  IsArray,
  IsBoolean,
  IsDate,
  IsInt,
  IsOptional,
  IsString,
  Max,
  MaxLength,
  Min,
  ValidateNested,
} from 'class-validator';

/** One popup campaign of the list. */
export class UpdateHomePopupItemDto {
  @ApiPropertyOptional({
    example: 'Tết 2027 VN',
    description: 'Admin-facing campaign label. Never shown in the app',
  })
  @IsOptional()
  @IsString()
  @MaxLength(200)
  name?: string;

  @ApiProperty({
    example: 'https://cdn.meup.training/home-popup/tet-2026.png',
    description:
      'The popup image (R2 upload) -- copy is baked into it. A campaign with ' +
      'no image is stored but never shown. CHANGING image or link STARTS A NEW ' +
      'CAMPAIGN (the campaign key is a hash of both)',
  })
  @IsString()
  @MaxLength(2048)
  imageUrl: string;

  @ApiPropertyOptional({
    example: 'https://meup.training/r/tet-2026',
    description:
      'Where tapping lands. Also part of the campaign key. Empty = the popup ' +
      'can only be dismissed',
  })
  @IsOptional()
  @IsString()
  @MaxLength(2048)
  linkUrl?: string;

  @ApiPropertyOptional({
    type: [String],
    example: ['VN'],
    description: 'Market allow-list. LEAVE EMPTY to show everywhere',
  })
  @IsOptional()
  @IsArray()
  @ArrayMaxSize(250)
  @IsString({ each: true })
  countries?: string[];

  @ApiPropertyOptional({
    type: [String],
    example: ['vi'],
    description:
      'Language allow-list (vi, en, zh, ja, ko). LEAVE EMPTY for every language',
  })
  @IsOptional()
  @IsArray()
  @ArrayMaxSize(50)
  @IsString({ each: true })
  locales?: string[];

  @ApiPropertyOptional({
    type: [String],
    description:
      'Segment allow-list (segment ids). LEAVE EMPTY for everyone; matching ' +
      'ANY listed segment is enough',
  })
  @IsOptional()
  @IsArray()
  @ArrayMaxSize(20)
  @IsString({ each: true })
  segmentIds?: string[];

  @ApiPropertyOptional({
    default: 0,
    description:
      'Higher wins when several campaigns target the same viewer; the user is ' +
      'shown the best one they have not tapped yet',
  })
  @IsOptional()
  @IsInt()
  @Min(-1000)
  @Max(1000)
  priority?: number;

  @ApiPropertyOptional({
    example: '2027-02-01T00:00:00.000Z',
    description: 'Campaign window start (server clock). Omit = already started',
  })
  @IsOptional()
  @IsDate()
  @Type(() => Date)
  startAt?: Date | null;

  @ApiPropertyOptional({
    example: '2027-02-20T00:00:00.000Z',
    description: 'Campaign window end (server clock). Omit = never expires',
  })
  @IsOptional()
  @IsDate()
  @Type(() => Date)
  endAt?: Date | null;

  @ApiPropertyOptional({
    default: true,
    description:
      'Per-campaign switch. False keeps the creative staged without showing it',
  })
  @IsOptional()
  @IsBoolean()
  enabled?: boolean;

  @ApiPropertyOptional({
    default: false,
    description:
      'Keep showing this campaign even to somebody who has already tapped it. ' +
      'The tap is still recorded (the CTR figure needs it) -- it just stops ' +
      'retiring the popup. Still once per app session, and still behind every ' +
      'other filter',
  })
  @IsOptional()
  @IsBoolean()
  alwaysShow?: boolean;
}

export class UpdateHomePopupConfigDto {
  @ApiPropertyOptional({
    default: false,
    description:
      'Kill switch. False stops the popup without an app release, and lets a ' +
      'campaign be staged before going live',
  })
  @IsOptional()
  @IsBoolean()
  enabled?: boolean;

  @ApiPropertyOptional({
    example: 'https://cdn.meup.training/home-popup/tet-2026.png',
    description:
      'The popup image (R2 upload) -- copy is baked into it. Empty also hides ' +
      'the popup. CHANGING THIS STARTS A NEW CAMPAIGN: the campaign key is a ' +
      'hash of image + link, so everyone who tapped the previous one sees this one',
  })
  @IsOptional()
  @IsString()
  @MaxLength(2048)
  imageUrl?: string;

  @ApiPropertyOptional({
    example: 'https://meup.training/r/tet-2026',
    description:
      'Where tapping the image lands. Also part of the campaign key -- see ' +
      'imageUrl. Empty = the popup can only be dismissed',
  })
  @IsOptional()
  @IsString()
  @MaxLength(2048)
  linkUrl?: string;

  @ApiPropertyOptional({
    type: [String],
    example: ['VN'],
    description:
      'Market allow-list. LEAVE EMPTY to show everywhere. Matched against the ' +
      'viewer resolved markets (IP, device region, app language), so picking VN ' +
      'still reaches Vietnamese readers abroad',
  })
  @IsOptional()
  @IsArray()
  @ArrayMaxSize(250)
  @IsString({ each: true })
  countries?: string[];

  @ApiPropertyOptional({
    type: [UpdateHomePopupItemDto],
    description:
      'Every campaign, staged or live. Sending this REPLACES the whole list ' +
      '(same rule as the banner slides). Omit it to leave the list untouched',
  })
  @IsOptional()
  @IsArray()
  // Ten is far past any real campaign roster and keeps a document read on
  // every Home open from growing unbounded.
  @ArrayMaxSize(10)
  @ValidateNested({ each: true })
  @Type(() => UpdateHomePopupItemDto)
  popups?: UpdateHomePopupItemDto[];
}
