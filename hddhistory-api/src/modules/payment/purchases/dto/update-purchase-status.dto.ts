import { ApiProperty } from '@nestjs/swagger';
import { IsEnum, IsNotEmpty, IsString } from 'class-validator';

import { PurchaseStatus } from '../../enum/payment.enum';

export class UpdatePurchaseStatusDto {
  @ApiProperty({ description: 'Admin password confirmation' })
  @IsString()
  @IsNotEmpty()
  confirmPassword: string;

  @ApiProperty({ enum: PurchaseStatus })
  @IsNotEmpty()
  @IsEnum(PurchaseStatus)
  status: PurchaseStatus;
}
