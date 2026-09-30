import { ApiProperty } from '@nestjs/swagger';
import { IsEnum, IsNotEmpty, IsString } from 'class-validator';

import { PaymentPlatform } from '../../enum/payment.enum';

export class CreateVoucherMappingDto {
  @ApiProperty({
    enum: PaymentPlatform,
    required: true,
    example: PaymentPlatform.GOOGLE,
  })
  @IsEnum(PaymentPlatform)
  @IsNotEmpty()
  platform: PaymentPlatform;

  @ApiProperty({
    required: true,
    example: 'meup_sub_1m',
    description: 'SKU shown normally',
  })
  @IsString()
  @IsNotEmpty()
  baseProductId: string;

  @ApiProperty({
    required: true,
    example: 'meup_sub_1m_50off',
    description: 'Discounted SKU to show instead of baseProductId',
  })
  @IsString()
  @IsNotEmpty()
  targetProductId: string;
}
