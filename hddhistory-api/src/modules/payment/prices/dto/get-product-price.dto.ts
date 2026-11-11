import { ApiPropertyOptional } from '@nestjs/swagger';
import { IsEnum, IsOptional, IsString } from 'class-validator';

import { PaymentPlatform } from '../../enum/payment.enum';

export class GetProductPriceDto {
  @ApiPropertyOptional({
    example: 'meup_sub_1y_30off',
    description: 'Restrict to one SKU. Omitted = every synced SKU.',
  })
  @IsOptional()
  @IsString()
  productId?: string;

  @ApiPropertyOptional({
    enum: PaymentPlatform,
    example: PaymentPlatform.APPLE,
    description: 'Restrict to one store. Omitted = both.',
  })
  @IsOptional()
  @IsEnum(PaymentPlatform)
  platform?: PaymentPlatform;

  @ApiPropertyOptional({
    example: 'USA,VNM,JPN',
    description:
      'Comma-separated territory codes. Omitted = every territory. The ' +
      'admin price matrix shows a fixed set of markets, and a single SKU has ' +
      '~175 territories, so without this it would download thousands of rows ' +
      'to display a dozen. Codes differ per store (Apple ISO alpha-3, Google ' +
      'alpha-2) — pass whichever the rows were stored with.',
  })
  @IsOptional()
  @IsString()
  territories?: string;
}
