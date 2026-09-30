import { ApiPropertyOptional } from '@nestjs/swagger';
import { Type } from 'class-transformer';
import { IsEnum, IsOptional, IsString } from 'class-validator';

import { OrderType } from '@utils/type/orderByType';

export class PageOptionsDto {
  @ApiPropertyOptional({ enum: OrderType, default: OrderType.DESC })
  @IsEnum(OrderType)
  @IsOptional()
  readonly order?: OrderType = OrderType.DESC;

  @ApiPropertyOptional({
    default: 'createdAt',
  })
  @IsOptional()
  readonly orderBy?: string = 'createdAt';

  @ApiPropertyOptional({
    minimum: 1,
    default: 1,
  })
  @IsOptional()
  @Type(() => Number)
  readonly page?: number = 1;

  @ApiPropertyOptional({
    minimum: 1,
    default: 10,
  })
  @IsOptional()
  @Type(() => Number)
  readonly take?: number = 10;

  @ApiPropertyOptional({ required: false })
  @IsOptional()
  @IsString()
  search?: string;
}
