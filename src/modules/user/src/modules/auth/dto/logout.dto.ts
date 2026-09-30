import { ApiProperty } from '@nestjs/swagger';
import { Type } from 'class-transformer';
import { IsNotEmptyObject, IsObject, ValidateNested } from 'class-validator';

import { DeviceDto } from './device.dto';

export class LogoutDto {
  @IsObject()
  @ApiProperty({ required: true, example: DeviceDto })
  @IsNotEmptyObject()
  @ValidateNested({ each: true })
  @Type(() => DeviceDto)
  device: DeviceDto;
}
