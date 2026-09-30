import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { IsNotEmpty, IsOptional, IsString } from 'class-validator';

export class DeviceDto {
  @ApiProperty({ example: 'macos_chipintel', required: true })
  @IsString()
  @IsNotEmpty()
  deviceId: string;

  @ApiPropertyOptional({ example: 'macos', required: false })
  @IsString()
  @IsOptional()
  deviceName: string;
}
