import {
  ApiProperty,
  ApiPropertyOptional,
  IntersectionType,
} from '@nestjs/swagger';
import {
  IsEnum,
  IsNotEmpty,
  IsNumber,
  IsOptional,
  IsString,
} from 'class-validator';

import { PageOptionsDto } from '@utils/dto/paging/page.dto';

import {
  PaymentEnvironment,
  PaymentPlatform,
  SubscriptionStatus,
} from '../../enum/payment.enum';

export class GetListSubscriptionDto extends IntersectionType(PageOptionsDto) {
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
    enum: SubscriptionStatus,
    required: false,
    example: SubscriptionStatus.ACTIVE,
  })
  @IsEnum(SubscriptionStatus)
  @IsOptional()
  status: SubscriptionStatus;

  @ApiProperty({ required: false })
  @IsString()
  @IsOptional()
  userId: string;
}
