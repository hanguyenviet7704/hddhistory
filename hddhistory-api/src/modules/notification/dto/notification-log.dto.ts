import { ApiPropertyOptional } from '@nestjs/swagger';
import { Type } from 'class-transformer';
import { IsEnum, IsInt, IsOptional, IsString, Matches, Min } from 'class-validator';

import { DEFAULT_APP_ENV } from 'src/modules/analytics/constant/dashboard.constant';

import { NotificationLogStatus, NotificationType } from '../notification.enum';

const LOCAL_DATE = /^\d{4}-\d{2}-\d{2}$/;

export class GetNotificationLogDto {
  @ApiPropertyOptional({ example: 1 })
  @IsOptional()
  @Type(() => Number)
  @IsInt()
  @Min(1)
  page?: number;

  @ApiPropertyOptional({ example: 20 })
  @IsOptional()
  @Type(() => Number)
  @IsInt()
  @Min(1)
  take?: number;

  @ApiPropertyOptional({ description: 'Filter to one user id' })
  @IsOptional()
  @IsString()
  userId?: string;

  @ApiPropertyOptional({ enum: NotificationType })
  @IsOptional()
  @IsEnum(NotificationType)
  type?: NotificationType;

  @ApiPropertyOptional({ enum: NotificationLogStatus })
  @IsOptional()
  @IsEnum(NotificationLogStatus)
  status?: NotificationLogStatus;

  @ApiPropertyOptional({
    example: '2026-07-01',
    description: "User's local date, inclusive",
  })
  @IsOptional()
  @Matches(LOCAL_DATE, { message: 'fromDate must be YYYY-MM-DD' })
  fromDate?: string;

  @ApiPropertyOptional({ example: '2026-07-31' })
  @IsOptional()
  @Matches(LOCAL_DATE, { message: 'toDate must be YYYY-MM-DD' })
  toDate?: string;
}

export class GetNotificationSummaryDto {
  @ApiPropertyOptional({ example: '2026-07-01' })
  @IsOptional()
  @Matches(LOCAL_DATE, { message: 'fromDate must be YYYY-MM-DD' })
  fromDate?: string;

  @ApiPropertyOptional({ example: '2026-07-31' })
  @IsOptional()
  @Matches(LOCAL_DATE, { message: 'toDate must be YYYY-MM-DD' })
  toDate?: string;

  @ApiPropertyOptional({
    example: DEFAULT_APP_ENV,
    description:
      'Which app builds the CLICK count reads (prod / stg / dev). Only the ' +
      'clicks are scoped by it: sends live in this API\'s own database and ' +
      'carry no environment at all. Defaults to the same value the product ' +
      'dashboard defaults to, so the two screens never disagree by accident.',
  })
  @IsOptional()
  @IsString()
  appEnv?: string = DEFAULT_APP_ENV;
}
