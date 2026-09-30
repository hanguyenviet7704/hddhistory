import {
  ApiProperty,
  ApiPropertyOptional,
  IntersectionType,
} from '@nestjs/swagger';
import { IsEnum, IsNotEmpty, IsNumber, IsOptional } from 'class-validator';

import { PageOptionsDto } from '@utils/dto/paging/page.dto';

import {
  PaymentEnvironment,
  PaymentPlatform,
  PurchaseStatus,
} from '../../enum/payment.enum';

export class GetListPurchaseDto extends IntersectionType(PageOptionsDto) {
  @ApiProperty({ required: true })
  @IsNotEmpty()
  @IsNumber()
  page: number;

  @ApiProperty({ required: true })
  @IsNotEmpty()
  @IsNumber()
  take: number;

  @ApiProperty({
    enum: PaymentPlatform,
    required: false,
    example: PaymentPlatform.GOOGLE,
  })
  @IsOptional()
  @IsEnum(PaymentPlatform)
  platform: PaymentPlatform;

  @ApiPropertyOptional({ enum: PaymentEnvironment })
  @IsOptional()
  @IsEnum(PaymentEnvironment)
  environment?: PaymentEnvironment;

  @ApiProperty({
    enum: PurchaseStatus,
    required: false,
    example: PurchaseStatus.PAID,
  })
  @IsEnum(PurchaseStatus)
  @IsOptional()
  status: PurchaseStatus;
}
