import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import {
  IsEnum,
  IsNotEmpty,
  IsOptional,
  IsString,
  MaxLength,
} from 'class-validator';

import { PaymentPlatform } from '../../enum/payment.enum';

export class VerifyPurchaseDto {
  @ApiProperty({
    enum: PaymentPlatform,
    required: true,
    example: PaymentPlatform.GOOGLE,
  })
  @IsEnum(PaymentPlatform)
  @IsNotEmpty()
  platform: PaymentPlatform;

  @ApiProperty({
    description: 'purchaseToken (Google) hoặc transactionId (Apple)',
    required: true,
    example: 'ender-1234567890',
  })
  @IsString()
  @IsNotEmpty()
  storeTransactionId: string;

  @ApiProperty({
    description: 'SKU / productId',
    required: true,
    example: 'monthyly_1',
  })
  @IsString()
  @IsNotEmpty()
  productId: string;

  @ApiPropertyOptional({
    description: 'Google package name (required for Android verify)',
    required: false,
  })
  @IsOptional()
  @IsString()
  packageName?: string;

  @ApiPropertyOptional({
    description: 'Idempotency key to dedupe retries',
    required: false,
  })
  @IsOptional()
  @IsString()
  idempotencyKey?: string;

  @ApiPropertyOptional({
    description:
      'Voucher code applied on the paywall, if any. Re-validated ' +
      'server-side at verify time -- a stale/invalid code never fails the ' +
      'purchase, it is just not recorded.',
    example: 'SUMMER50',
  })
  @IsOptional()
  @IsString()
  voucherCode?: string;

  @ApiPropertyOptional({
    description:
      'Id of the paywall LogicSale campaign the buyer purchased through ' +
      '(from GET /paywall-config/logic-sale). Attribution only -- it is ' +
      'stored on the purchase row for the campaign statistics and never ' +
      'affects the price, the product, or the verify outcome.',
    example: 'ls-tet-2027',
  })
  @IsOptional()
  @IsString()
  @MaxLength(64)
  logicSaleId?: string;

  @ApiPropertyOptional({
    description:
      'Key of the paywall body A/B run the buyer was assigned to (from ' +
      'GET /paywall-config/logic-sale). Attribution only -- stored on the ' +
      'purchase row so the readout can count verified orders per arm.',
    example: 'paywall_body_2026_08',
  })
  @IsOptional()
  @IsString()
  @MaxLength(64)
  paywallExperimentKey?: string;

  @ApiPropertyOptional({
    description:
      'Arm of that run the buyer saw. Sent only when the viewer was actually ' +
      'IN the test, so excluded viewers never inflate an arm.',
    enum: ['benefits', 'comparison'],
    example: 'comparison',
  })
  @IsOptional()
  @IsString()
  @MaxLength(16)
  paywallBodyVariant?: string;
}
