import { ApiProperty } from '@nestjs/swagger';
import {
  IsBoolean,
  IsEnum,
  IsNotEmpty,
  IsNumber,
  IsOptional,
  IsString,
  MaxLength,
} from 'class-validator';

import {
  PaymentCurrency,
  PaymentPlatform,
  ProductType,
} from '../../enum/payment.enum';

export class CreateProductDto {
  @ApiProperty({
    enum: PaymentPlatform,
    required: true,
    example: PaymentPlatform.GOOGLE,
  })
  @IsNotEmpty()
  @IsEnum(PaymentPlatform)
  platform: PaymentPlatform;

  @ApiProperty({ required: true, example: 'com.example.app' })
  @IsString()
  @IsNotEmpty()
  productId: string;

  @ApiProperty({
    enum: ProductType,
    required: true,
    example: ProductType.SUBSCRIPTION_AUTO_RENEW,
  })
  @IsEnum(ProductType)
  @IsNotEmpty()
  type: ProductType;

  @ApiProperty({ required: true, example: 'Premium Monthly' })
  @IsString()
  @IsNotEmpty()
  title: string;

  @ApiProperty({ required: false, example: 'Gói premium 1 tháng' })
  @IsOptional()
  @IsString()
  description?: string;

  @ApiProperty({
    enum: PaymentCurrency,
    required: false,
    example: PaymentCurrency.USD,
  })
  @IsOptional()
  @IsEnum(PaymentCurrency)
  currency?: PaymentCurrency;

  @ApiProperty({ required: false, type: Number, example: 9.99 })
  @IsOptional()
  @IsNumber()
  rawPrice?: number;

  @ApiProperty({ required: false, type: String, example: '$9.99' })
  @IsOptional()
  @IsString()
  price?: string;

  @ApiProperty({ required: false, type: Number, example: 4.99 })
  @IsOptional()
  @IsNumber()
  salePrice?: number;

  @ApiProperty({ required: false, default: true })
  @IsOptional()
  @IsBoolean()
  isActive?: boolean;

  @ApiProperty({ required: false, default: false })
  @IsOptional()
  @IsBoolean()
  bestDeal?: boolean;

  @ApiProperty({
    required: false,
    type: Number,
    example: 50,
    description: 'Discount % shown on paywall badge (0–100). Null = no badge.',
  })
  @IsOptional()
  @IsNumber()
  salePercent?: number;

  @ApiProperty({
    required: false,
    type: String,
    example: 'meup_sub_1y',
    description:
      'SKU on the same platform whose real store price the paywall strikes ' +
      'through above this one. Must exist in iap_products for this platform ' +
      'and differ from productId. Empty string or null clears it.',
  })
  @IsOptional()
  @IsString()
  @MaxLength(255)
  compareAtProductId?: string;
}
