import { ApiProperty } from '@nestjs/swagger';
import { Type } from 'class-transformer';
import {
  IsNotEmpty,
  IsNotEmptyObject,
  IsObject,
  IsString,
  ValidateNested,
} from 'class-validator';

import { DeviceDto } from './device.dto';

export class RefreshTokenDto {
  @ApiProperty({ example: 'eyJhbGciOiJIUzI1Ni....', required: true })
  @IsString()
  @IsNotEmpty()
  refreshToken: string;

  @IsObject()
  @ApiProperty({ required: true, example: DeviceDto })
  @IsNotEmptyObject()
  @ValidateNested({ each: true })
  @Type(() => DeviceDto)
  device: DeviceDto;
}
