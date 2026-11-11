import { ApiPropertyOptional } from '@nestjs/swagger';
import { Type } from 'class-transformer';
import {
  IsDateString,
  IsEnum,
  IsNotEmpty,
  IsOptional,
  IsString,
  Max,
  Min,
} from 'class-validator';

import { UserEventKind } from '../enum/analytics.enum';

class DateRangeDto {
  @ApiPropertyOptional({ example: '2026-05-01T00:00:00.000Z' })
  @IsOptional()
  @IsDateString()
  from?: string;

  @ApiPropertyOptional({ example: '2026-08-03T23:59:59.000Z' })
  @IsOptional()
  @IsDateString()
  to?: string;

  @ApiPropertyOptional({ example: 'dev', description: 'dev | stg | prod' })
  @IsOptional()
  @IsString()
  appEnv?: string;
}

export class GetUserSummaryDto extends DateRangeDto {
  // Which event-name prefix counts as the funnel. The admin panel owns the step
  // ORDER; the api only reports when each matching event was first seen.
  @ApiPropertyOptional({ default: 'obd_' })
  @IsOptional()
  @IsString()
  funnelPrefix?: string = 'obd_';
}

export class GetUserSessionsDto extends DateRangeDto {
  @ApiPropertyOptional({ default: 100, minimum: 1, maximum: 200 })
  @IsOptional()
  @Type(() => Number)
  @Min(1)
  @Max(200)
  limit?: number = 100;
}

export class GetSessionEventsDto {
  @ApiPropertyOptional({ example: '9f2c1f7a-1b4e-4c2a-9a3e-2f1d0c8b7a6e' })
  @IsString()
  @IsNotEmpty()
  sessionId: string;

  @ApiPropertyOptional({ example: 'obd_' })
  @IsOptional()
  @IsString()
  namePrefix?: string;

  @ApiPropertyOptional({ enum: UserEventKind })
  @IsOptional()
  @IsEnum(UserEventKind)
  kind?: UserEventKind;

  // Keyset cursor: clientTs of the last item already loaded.
  @ApiPropertyOptional({ example: '2026-08-03T08:12:44.000Z' })
  @IsOptional()
  @IsDateString()
  cursor?: string;

  @ApiPropertyOptional({ default: 50, minimum: 1, maximum: 200 })
  @IsOptional()
  @Type(() => Number)
  @Min(1)
  @Max(200)
  limit?: number = 50;
}
