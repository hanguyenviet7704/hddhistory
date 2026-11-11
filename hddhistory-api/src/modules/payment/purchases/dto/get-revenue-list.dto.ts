import {
  ApiPropertyOptional,
  IntersectionType,
} from '@nestjs/swagger';
import {
  IsDateString,
  IsEnum,
  IsOptional,
  IsString,
} from 'class-validator';

import { PageOptionsDto } from '@utils/dto/paging/page.dto';

import {
  PaymentCurrency,
  PaymentEnvironment,
  PaymentPlatform,
  PurchaseEventType,
} from '../../enum/payment.enum';

export class GetRevenueListDto extends IntersectionType(PageOptionsDto) {
  @ApiPropertyOptional({ description: 'ISO date from (inclusive)' })
  @IsOptional()
  @IsDateString()
  from?: string;

  @ApiPropertyOptional({ description: 'ISO date to (inclusive)' })
  @IsOptional()
  @IsDateString()
  to?: string;

  @ApiPropertyOptional({ enum: PaymentPlatform })
  @IsOptional()
  @IsEnum(PaymentPlatform)
  platform?: PaymentPlatform;

  @ApiPropertyOptional({ enum: PaymentEnvironment })
  @IsOptional()
  @IsEnum(PaymentEnvironment)
  environment?: PaymentEnvironment;

  @ApiPropertyOptional({ description: 'Filter by productId' })
  @IsOptional()
  @IsString()
  productId?: string;

  @ApiPropertyOptional({
    enum: PaymentCurrency,
    description: 'Filter by currency. Omit to include all currencies.',
  })
  @IsOptional()
  @IsEnum(PaymentCurrency)
  currency?: PaymentCurrency;

  @ApiPropertyOptional({
    enum: PurchaseEventType,
    description: 'Filter by event type (initial/renewal/refund/cancel)',
  })
  @IsOptional()
  @IsEnum(PurchaseEventType)
  eventType?: PurchaseEventType;
}
