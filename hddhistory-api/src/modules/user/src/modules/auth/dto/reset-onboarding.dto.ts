import { ApiPropertyOptional } from '@nestjs/swagger';
import { IsOptional, IsString } from 'class-validator';

export class ResetOnboardingDto {
  @ApiPropertyOptional({ example: 'user@example.com' })
  @IsString()
  @IsOptional()
  email?: string;

  @ApiPropertyOptional({ example: '64f1a2b3c4d5e6f7a8b9c0d1' })
  @IsString()
  @IsOptional()
  userId?: string;
}
