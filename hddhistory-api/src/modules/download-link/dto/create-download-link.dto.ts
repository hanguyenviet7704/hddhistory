import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { Transform } from 'class-transformer';
import {
  IsBoolean,
  IsNotEmpty,
  IsOptional,
  IsString,
  IsUrl,
  Matches,
  MaxLength,
} from 'class-validator';

export class CreateDownloadLinkDto {
  @ApiProperty({
    required: true,
    example: 'zalo-thang-8',
    description:
      'URL segment after /r/. Lowercase letters, digits and hyphens only ' +
      '-- it ends up in printed material and QR codes, so anything ' +
      'case-sensitive or easy to mistype is rejected here rather than ' +
      'discovered later.',
  })
  @IsString()
  @IsNotEmpty()
  @MaxLength(64)
  @Transform(({ value }) =>
    typeof value === 'string' ? value.trim().toLowerCase() : value,
  )
  @Matches(/^[a-z0-9][a-z0-9-]*$/, {
    message:
      'slug must contain only lowercase letters, digits and hyphens, and ' +
      'must not start with a hyphen',
  })
  slug: string;

  @ApiProperty({ required: true, example: 'Zalo OA - chiến dịch tháng 8' })
  @IsString()
  @IsNotEmpty()
  @MaxLength(255)
  name: string;

  @ApiPropertyOptional({ example: 'Đăng ở Zalo OA ngày 01/08' })
  @IsOptional()
  @IsString()
  @MaxLength(500)
  description?: string;

  @ApiPropertyOptional({ example: 'zalo' })
  @IsOptional()
  @IsString()
  @MaxLength(100)
  utmSource?: string;

  @ApiPropertyOptional({ example: 'social' })
  @IsOptional()
  @IsString()
  @MaxLength(100)
  utmMedium?: string;

  @ApiPropertyOptional({ example: 'thang-8' })
  @IsOptional()
  @IsString()
  @MaxLength(100)
  utmCampaign?: string;

  @ApiPropertyOptional({
    example: 'HDDhistory — Học kỹ năng mềm mỗi ngày',
    description:
      'Title of the preview card chat apps and social feeds render when ' +
      'this link is shared. Empty = the generic HDDhistory card.',
  })
  @IsOptional()
  @IsString()
  @MaxLength(255)
  ogTitle?: string;

  @ApiPropertyOptional({ example: '7 ngày xây thói quen học cùng HDDhistory.' })
  @IsOptional()
  @IsString()
  @MaxLength(500)
  ogDescription?: string;

  @ApiPropertyOptional({
    example: 'https://meup.training/og-image.png',
    description:
      'Preview image as an absolute https URL, ideally 1200x630. Crawlers ' +
      'reject data: URIs, so an embedded image can never work here.',
  })
  @IsOptional()
  @IsUrl(
    { protocols: ['https'], require_protocol: true },
    { message: 'ogImage must be an absolute https:// URL' },
  )
  @MaxLength(500)
  ogImage?: string;

  @ApiPropertyOptional({ default: true })
  @IsOptional()
  @IsBoolean()
  isActive?: boolean;
}
