import { ApiProperty } from '@nestjs/swagger';
import { Type } from 'class-transformer';
import { IsDateString, IsNotEmpty, IsNumber, IsOptional, IsString } from 'class-validator';

export class UpdateManualSubscriptionDto {
  @ApiProperty({ description: 'Admin password confirmation' })
  @IsString()
  @IsNotEmpty()
  confirmPassword: string;

  @ApiProperty({ description: 'Expiry time ISO string' })
  @IsDateString()
  expiryTime: string;

  @ApiProperty({ description: 'New raw price', required: false })
  @IsOptional()
  @Type(() => Number)
  @IsNumber()
  rawPrice?: number;
}
