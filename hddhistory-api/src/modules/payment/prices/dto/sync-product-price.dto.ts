import { ApiPropertyOptional } from '@nestjs/swagger';
import { IsEnum, IsOptional, IsString } from 'class-validator';

import { PaymentPlatform } from '../../enum/payment.enum';

export class SyncProductPriceDto {
  @ApiPropertyOptional({
    enum: PaymentPlatform,
    example: PaymentPlatform.APPLE,
    description: 'Narrow the sync to one store. Omitted = sync both.',
  })
  @IsOptional()
  @IsEnum(PaymentPlatform)
  platform?: PaymentPlatform;

  @ApiPropertyOptional({
    example: 'meup_sub_1y_30off',
    description:
      'Narrow the sync to one SKU (synced regardless of its isActive flag). ' +
      'Omitted = every active product for the chosen platform(s).',
  })
  @IsOptional()
  @IsString()
  productId?: string;
}
