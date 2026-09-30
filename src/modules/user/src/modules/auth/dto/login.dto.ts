import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { Type } from 'class-transformer';
import {
  IsEmail,
  IsEnum,
  IsNotEmpty,
  IsNotEmptyObject,
  IsObject,
  IsOptional,
  IsString,
  ValidateNested,
} from 'class-validator';

import { DeviceDto } from './device.dto';
import { OnboardingDto } from './onboarding.dto';
import { ProviderType } from '../enum/user.enum';

export class LoginDto {
  @ApiProperty({
    example: 'eup@gmail.com',
    required: true,
  })
  @IsEmail()
  @IsNotEmpty()
  email: string;

  @ApiProperty({
    example: '12345',
    required: true,
  })
  @IsString()
  @IsNotEmpty()
  password: string;

  @IsObject()
  @ApiProperty({ required: true, example: DeviceDto })
  @IsNotEmptyObject()
  @ValidateNested({ each: true })
  @Type(() => DeviceDto)
  device: DeviceDto;
}

export class AnonymousDto {
  @IsObject()
  @ApiProperty({ required: true, example: DeviceDto })
  @IsNotEmptyObject()
  @ValidateNested({ each: true })
  @Type(() => DeviceDto)
  device: DeviceDto;

  @ApiPropertyOptional({
    example: 'NGUYEN VAN A',
    required: true,
  })
  @IsOptional()
  @IsString()
  name: string;

  @ApiPropertyOptional({
    example: 'en',
    required: false,
  })
  @IsOptional()
  @IsString()
  language: string;

  @ApiPropertyOptional({
    example: '25-35',
    required: false,
  })
  @IsOptional()
  @IsString()
  age: string;

  @ApiPropertyOptional({
    example: 'Male',
    required: false,
  })
  @IsOptional()
  @IsString()
  gender: string;

  @IsObject()
  @ApiPropertyOptional({
    type: OnboardingDto,
    required: false,
    example: OnboardingDto,
  })
  @IsOptional()
  @ValidateNested({ each: true })
  @Type(() => OnboardingDto)
  onboarding: OnboardingDto;
}

export class DevLoginDto {
  @ApiProperty({ example: 'user@gmail.com', required: true })
  @IsEmail()
  @IsNotEmpty()
  email: string;

  @ApiPropertyOptional({ example: 'dev-swagger-001' })
  @IsString()
  @IsOptional()
  deviceId?: string;
}

export class LoginWithProviderDto {
  @IsObject()
  @ApiProperty({ required: true, example: DeviceDto })
  @IsNotEmptyObject()
  @ValidateNested({ each: true })
  @Type(() => DeviceDto)
  device: DeviceDto;

  @ApiProperty({
    enum: ProviderType,
    required: true,
    example: ProviderType.GOOGLE,
  })
  @IsEnum(ProviderType)
  @IsNotEmpty()
  provider: ProviderType;

  // The _id of the anonymous (guest) user currently signed in on this device,
  // if any. Lets the provider login upgrade THAT guest in place (same _id, so
  // all userId-keyed data — progress, habits, streaks — is preserved) instead
  // of relying solely on a deviceId match, which breaks after reinstall / new
  // device and silently orphaned the guest's progress.
  @ApiPropertyOptional({ example: '507f1f77bcf86cd799439011' })
  @IsString()
  @IsOptional()
  anonymousUserId?: string;
}
