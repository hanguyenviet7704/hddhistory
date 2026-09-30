import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { Type } from 'class-transformer';
import { IsInt, IsNotEmpty, IsOptional, IsString, Max, Min } from 'class-validator';

/**
 * Body contract for `POST /purchase/affiliateOrder` (Part 5 of the
 * voucher/affiliate design). Field names are snake_case on purpose -- this is
 * an external, fixed contract owned by the affiliate team, not a HDDhistory-style
 * DTO.
 */
export class AffiliateOrderRequestDto {
  @ApiProperty({
    required: true,
    description:
      'Shared secret identifying the calling affiliate project. Checked ' +
      'against AFFILIATE_ORDERS_SECRET_TOKEN with a timing-safe comparison.',
    example: 'affiliate-shared-secret',
  })
  @IsString()
  @IsNotEmpty()
  key_project: string;

  @ApiProperty({
    required: true,
    description: 'Range start, epoch milliseconds (inclusive)',
    example: 1732000000000,
  })
  @Type(() => Number)
  @IsInt()
  @IsNotEmpty()
  start_time: number;

  @ApiProperty({
    required: true,
    description: 'Range end, epoch milliseconds (inclusive)',
    example: 1732600000000,
  })
  @Type(() => Number)
  @IsInt()
  @IsNotEmpty()
  end_time: number;

  @ApiPropertyOptional({
    description: 'Page size, capped at 500',
    default: 100,
    example: 100,
  })
  @IsOptional()
  @Type(() => Number)
  @IsInt()
  @Min(1)
  @Max(500)
  limit?: number;

  @ApiPropertyOptional({ description: 'Offset', default: 0, example: 0 })
  @IsOptional()
  @Type(() => Number)
  @IsInt()
  @Min(0)
  skip?: number;
}
