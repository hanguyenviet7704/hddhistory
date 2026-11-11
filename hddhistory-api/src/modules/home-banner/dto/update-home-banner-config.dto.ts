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

/**
 * One slide of the Home carousel. Position in the array is the display order.
 */
export class UpdateHomeBannerSlideDto {
  @ApiPropertyOptional({
    example: 'Tết 2027 VN',
    description: 'Admin-facing campaign label. Never shown in the app',
  })
  @IsOptional()
  @IsString()
  @MaxLength(200)
  name?: string;

  @ApiProperty({
    example: 'https://cdn.meup.training/home-banner/tet-2026.png',
    description:
      'Slide image URL (R2 upload). A slide with no image is stored but never ' +
      'shown -- the admin adds the row before uploading into it',
  })
  @IsString()
  @MaxLength(2048)
  imageUrl: string;

  @ApiPropertyOptional({
    example: 'https://meup.training/r/tet-2026',
    description: 'Tap destination: https:// URL or deeplink. Empty = not tappable',
  })
  @IsOptional()
  @IsString()
  @MaxLength(2048)
  linkUrl?: string;

  @ApiPropertyOptional({
    type: [String],
    example: ['VN'],
    description:
      'Per-slide market allow-list. LEAVE EMPTY for every market. Matched ' +
      'against the viewer resolved markets (IP, device region, app language)',
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
      'Per-slide language allow-list (vi, en, zh, ja, ko). LEAVE EMPTY for ' +
      'every language. Matched against the `lang` header the app sends',
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
      'Higher shows first; ties keep the array order (the "thứ tự treo")',
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
      'Per-slide switch. False keeps the image and link staged without showing ' +
      'the slide',
  })
  @IsOptional()
  @IsBoolean()
  enabled?: boolean;
}

export class UpdateHomeBannerConfigDto {
  @ApiPropertyOptional({
    default: false,
    description:
      'Kill switch. False hides the banner without an app release, and lets ' +
      'a banner be staged before going live',
  })
  @IsOptional()
  @IsBoolean()
  enabled?: boolean;

  @ApiPropertyOptional({
    example: 'https://cdn.meup.training/banners/tet-2026.png',
    description: 'Banner image URL (R2 upload). Empty also hides the banner',
  })
  @IsOptional()
  @IsString()
  @MaxLength(2048)
  imageUrl?: string;

  @ApiPropertyOptional({
    example: 'https://meup.training/r/tet-2026',
    description:
      'Where a tap lands: https:// URL or app deeplink. Empty = not tappable',
  })
  @IsOptional()
  @IsString()
  @MaxLength(2048)
  linkUrl?: string;

  @ApiPropertyOptional({
    type: [String],
    example: ['VN'],
    description:
      'ISO-3166 alpha-2 allow-list. LEAVE EMPTY to show the banner ' +
      'everywhere. Codes are upper-cased and de-duplicated on write, and ' +
      'anything that is not two letters is dropped',
  })
  @IsOptional()
  @IsArray()
  // Far above any real campaign, and only here so a malformed client cannot
  // push an unbounded array into a config document read on every Home open.
  @ArrayMaxSize(250)
  @IsString({ each: true })
  countries?: string[];

  @ApiPropertyOptional({
    type: [UpdateHomeBannerSlideDto],
    description:
      'The carousel, in display order. Sending this REPLACES the whole list ' +
      '(order is the data, and a per-index merge could not express deleting a ' +
      'middle slide). Omit it to leave the carousel untouched',
  })
  @IsOptional()
  @IsArray()
  // Ten is far past any real campaign and keeps a document that is read on every
  // Home open from growing unbounded.
  @ArrayMaxSize(10)
  @ValidateNested({ each: true })
  @Type(() => UpdateHomeBannerSlideDto)
  slides?: UpdateHomeBannerSlideDto[];
}
