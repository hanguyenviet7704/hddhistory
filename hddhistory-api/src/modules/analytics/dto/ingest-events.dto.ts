import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import {
  ArrayMaxSize,
  ArrayNotEmpty,
  IsArray,
  IsEnum,
  IsNotEmpty,
  IsNumber,
  IsObject,
  IsOptional,
  IsString,
  MaxLength,
} from 'class-validator';

import { UserEventKind } from '../enum/analytics.enum';

// Shape of one queued event. Declared for Swagger and for typing only — it is
// deliberately NOT @ValidateNested-ed on the parent: a single malformed event
// (old app version, missing field) must never 400 the whole batch. The service
// drops bad entries and reports how many it accepted.
export class TrackEventDto {
  @ApiProperty({ example: 'keypoint_start' })
  @IsString()
  @IsNotEmpty()
  @MaxLength(150)
  name: string;

  @ApiPropertyOptional({ enum: UserEventKind, default: UserEventKind.EVENT })
  @IsOptional()
  @IsEnum(UserEventKind)
  kind?: UserEventKind;

  @ApiProperty({ example: '9f2c1f7a-1b4e-4c2a-9a3e-2f1d0c8b7a6e' })
  @IsString()
  @IsNotEmpty()
  sessionId: string;

  @ApiProperty({ example: 1780000000000, description: 'epoch millis' })
  @IsNumber()
  clientTs: number;

  @ApiPropertyOptional({ example: { course_id: '…', course_name: '…' } })
  @IsOptional()
  @IsObject()
  params?: Record<string, any>;
}

export class IngestEventsDto {
  @ApiProperty({ example: 'A1B2C3D4' })
  @IsString()
  @IsNotEmpty()
  deviceId: string;

  @ApiPropertyOptional({ example: 'dev' })
  @IsOptional()
  @IsString()
  appEnv?: string;

  @ApiPropertyOptional({ example: '1.12.0' })
  @IsOptional()
  @IsString()
  appVersion?: string;

  @ApiPropertyOptional({ example: 'ios' })
  @IsOptional()
  @IsString()
  platform?: string;

  @ApiProperty({ type: [TrackEventDto] })
  @IsArray()
  @ArrayNotEmpty()
  @ArrayMaxSize(200)
  events: TrackEventDto[];
}
