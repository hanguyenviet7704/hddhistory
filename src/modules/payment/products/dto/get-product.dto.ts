import { ApiProperty, IntersectionType } from '@nestjs/swagger';
import {
  IsBoolean,
  IsEnum,
  IsNotEmpty,
  IsNumber,
  IsOptional,
} from 'class-validator';

import { ToBoolean } from '@utils/boolean.utils';
import { PageOptionsDto } from '@utils/dto/paging/page.dto';

import { PaymentPlatform, ProductType } from '../../enum/payment.enum';

export class GetListProductDto extends IntersectionType(PageOptionsDto) {
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

  @ApiProperty({ type: Boolean, example: true, required: false, default: true })
  @IsOptional()
  @IsBoolean()
  @ToBoolean()
  isActive?: boolean = true;

  @ApiProperty({ type: Boolean, example: true, required: false })
  @IsOptional()
  @IsBoolean()
  @ToBoolean()
  isAll: boolean;

  @ApiProperty({
    enum: ProductType,
    required: false,
    example: ProductType.SUBSCRIPTION_AUTO_RENEW,
  })
  @IsEnum(ProductType)
  @IsOptional()
  type: ProductType;
}
