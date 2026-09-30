import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { Type } from 'class-transformer';
import {
  IsArray,
  IsBoolean,
  IsDateString,
  IsInt,
  IsNotEmpty,
  IsOptional,
  IsString,
  Max,
  MaxLength,
  Min,
  ValidateNested,
} from 'class-validator';

import { CreateVoucherMappingDto } from './create-voucher-mapping.dto';

export class CreateVoucherDto {
  @ApiProperty({
    required: true,
    example: 'SUMMER50',
    description: 'Always stored trimmed + uppercased',
  })
  @IsString()
  @IsNotEmpty()
  @MaxLength(64)
  code: string;

  @ApiPropertyOptional({
    example: 'affiliate-eup-01',
    description: 'Affiliate owner, for reporting only',
  })
  @IsOptional()
  @IsString()
  @MaxLength(255)
  owner?: string;

  @ApiPropertyOptional({
    type: Number,
    example: 50,
    description:
      'DISPLAY/REPORTING ONLY (0-100). The real discount is whatever the ' +
      "target SKU costs in the user's territory; never compute a charge " +
      'from this field.',
  })
  @IsOptional()
  @IsInt()
  @Min(0)
  @Max(100)
  discountPercent?: number;

  @ApiPropertyOptional({
    example: '2026-08-01T00:00:00.000Z',
    description: 'ISO date-time. Null = no start restriction',
  })
  @IsOptional()
  @IsDateString()
  validFrom?: string;

  @ApiPropertyOptional({
    example: '2026-09-01T00:00:00.000Z',
    description: 'ISO date-time. Null = no end restriction',
  })
  @IsOptional()
  @IsDateString()
  validTo?: string;

  @ApiPropertyOptional({
    type: Number,
    example: 100,
    description: 'Total redemption cap. Null = unlimited',
  })
  @IsOptional()
  @IsInt()
  @Min(0)
  maxUses?: number;

  @ApiPropertyOptional({
    type: Number,
    example: 1,
    description: 'Per-user redemption cap. Null = unlimited',
  })
  @IsOptional()
  @IsInt()
  @Min(0)
  perUserLimit?: number;

  @ApiPropertyOptional({
    type: [String],
    example: ['VN', 'US'],
    description: 'ISO country allow-list. Empty/omitted = all countries',
  })
  @IsOptional()
  @IsArray()
  @IsString({ each: true })
  countries?: string[];

  @ApiPropertyOptional({ default: true })
  @IsOptional()
  @IsBoolean()
  isActive?: boolean;

  @ApiPropertyOptional({
    type: [CreateVoucherMappingDto],
    description: 'SKU swaps this voucher unlocks, per platform',
  })
  @IsOptional()
  @IsArray()
  @ValidateNested({ each: true })
  @Type(() => CreateVoucherMappingDto)
  mappings?: CreateVoucherMappingDto[];
}
