import { ApiPropertyOptional } from '@nestjs/swagger';
import { IsEnum, IsOptional } from 'class-validator';

import { PaymentEnvironment } from '../enum/payment.enum';

export class GetEnvironmentDto {
  @ApiPropertyOptional({ enum: PaymentEnvironment })
  @IsOptional()
  @IsEnum(PaymentEnvironment)
  environment?: PaymentEnvironment;
}
