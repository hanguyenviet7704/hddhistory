import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { Type } from 'class-transformer';
import {
  IsDateString,
  IsEmail,
  IsEnum,
  IsNotEmpty,
  IsNumber,
  IsOptional,
  IsString,
} from 'class-validator';

import {
  PaymentCurrency,
  PaymentEnvironment,
} from '../../enum/payment.enum';

export class ManualSubscriptionDto {
  @ApiProperty({ description: 'Admin password confirmation' })
  @IsString()
  @IsNotEmpty()
  confirmPassword: string;

  @ApiProperty({ description: 'User id' })
  @IsString()
  @IsNotEmpty()
  userId: string;

  @ApiProperty({ description: 'User name' })
  @IsString()
  @IsNotEmpty()
  userName: string;

  @ApiProperty({ description: 'User email' })
  @IsEmail()
  userEmail: string;

  @ApiProperty({ enum: PaymentEnvironment })
  @IsEnum(PaymentEnvironment)
  environment: PaymentEnvironment;

  @ApiProperty({ description: 'Product id (SKU)' })
  @IsString()
  @IsNotEmpty()
  productId: string;

  @ApiProperty({ enum: PaymentCurrency })
  @IsEnum(PaymentCurrency)
  currency: PaymentCurrency;

  @ApiProperty({ description: 'Raw price number' })
  @Type(() => Number)
  @IsNumber()
  rawPrice: number;

  @ApiProperty({ description: 'Purchase time ISO string' })
  @IsDateString()
  purchaseTime: string;

  @ApiPropertyOptional({ description: 'Expiry time ISO string' })
  @IsOptional()
  @IsDateString()
  expiryTime?: string | null;
}
