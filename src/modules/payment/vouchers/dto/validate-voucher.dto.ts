import { ApiProperty } from '@nestjs/swagger';
import { IsEnum, IsNotEmpty, IsString } from 'class-validator';

import { PaymentPlatform } from '../../enum/payment.enum';

export class ValidateVoucherDto {
  @ApiProperty({ required: true, example: 'SUMMER50' })
  @IsString()
  @IsNotEmpty()
  code: string;

  @ApiProperty({
    enum: PaymentPlatform,
    required: true,
    example: PaymentPlatform.GOOGLE,
  })
  @IsEnum(PaymentPlatform)
  @IsNotEmpty()
  platform: PaymentPlatform;
}
