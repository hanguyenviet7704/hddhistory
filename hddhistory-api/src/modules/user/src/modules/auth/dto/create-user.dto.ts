import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { Transform, Type } from 'class-transformer';
import {
  IsBoolean,
  IsDate,
  IsEmail,
  IsEnum,
  IsNotEmpty,
  IsObject,
  IsOptional,
  IsString,
  ValidateNested,
} from 'class-validator';
import dayjs from 'dayjs';

import { OnboardingDto } from './onboarding.dto';
import { UserRole, UserStatus } from '../enum/user.enum';

export class UserLastActionDto {
  @Transform(({ value }) => dayjs(value).toDate())
  @IsDate()
  @ApiProperty({ required: false })
  @IsOptional()
  time: Date;

  @ApiProperty({ required: true, example: 'complate lesson 1' })
  @IsNotEmpty()
  @IsString()
  action: string;
}

export class CreateUserDto {
  @ApiPropertyOptional({
    example: 'NGUYEN VAN A',
    required: false,
  })
  @IsOptional()
  @IsString()
  name: string;

  @ApiPropertyOptional({
    example: 'eup@gmail.com',
    required: true,
  })
  @IsEmail()
  @IsNotEmpty()
  email: string;

  @ApiPropertyOptional({
    example: '0949418096',
    required: false,
  })
  @IsOptional()
  @IsString()
  phone: string;

  @ApiPropertyOptional({
    example: 'https://...',
    required: false,
  })
  @IsOptional()
  @IsString()
  avatar: string;

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

  @ApiPropertyOptional({
    enum: UserRole,
    default: UserRole.USER,
    example: UserRole.USER,
    required: false,
  })
  @IsOptional()
  @IsEnum(UserRole)
  role: UserRole = UserRole.USER;

  @ApiPropertyOptional({
    enum: UserStatus,
    default: UserStatus.ACTIVE,
    example: UserStatus.ACTIVE,
    required: false,
  })
  @IsOptional()
  @IsEnum(UserStatus)
  status?: UserStatus = UserStatus.ACTIVE;

  @ApiPropertyOptional({
    example: 'en',
    required: false,
  })
  @IsOptional()
  @IsString()
  language: string;

  @ApiPropertyOptional({
    example: 'vietnam',
    required: false,
  })
  @IsOptional()
  @IsString()
  country: string;

  @ApiPropertyOptional({
    example: '1000',
    required: false,
  })
  @IsOptional()
  @IsString()
  enery: string;

  @IsObject()
  @ApiPropertyOptional({
    type: UserLastActionDto,
    example: UserLastActionDto,
    required: false,
  })
  @IsOptional()
  @ValidateNested({ each: true })
  @Type(() => UserLastActionDto)
  lastAction: UserLastActionDto;

  @IsObject()
  @ApiPropertyOptional({
    type: OnboardingDto,
    example: OnboardingDto,
    required: false,
  })
  @IsOptional()
  @ValidateNested({ each: true })
  @Type(() => OnboardingDto)
  onboarding: OnboardingDto;

  @ApiPropertyOptional({ type: Boolean })
  @IsOptional()
  @IsBoolean()
  @Transform(({ value }) => value === true || value === 'true' || value === 1)
  isOnboarded: boolean;
}
