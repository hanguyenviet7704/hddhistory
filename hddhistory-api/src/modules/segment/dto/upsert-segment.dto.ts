import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { Type } from 'class-transformer';
import {
  ArrayMaxSize,
  IsArray,
  IsDate,
  IsIn,
  IsInt,
  IsNotEmpty,
  IsNumber,
  IsOptional,
  IsString,
  Max,
  MaxLength,
  Min,
  ValidateNested,
} from 'class-validator';

import { USER_TYPES } from '../segment-match.util';

export class SegmentCriteriaDto {
  @ApiPropertyOptional({ example: '2027-01-01T00:00:00.000Z' })
  @IsOptional()
  @IsDate()
  @Type(() => Date)
  firstSessionFrom?: Date | null;

  @ApiPropertyOptional({ example: '2027-02-01T00:00:00.000Z' })
  @IsOptional()
  @IsDate()
  @Type(() => Date)
  firstSessionTo?: Date | null;

  @ApiPropertyOptional({ example: '2027-01-01T00:00:00.000Z' })
  @IsOptional()
  @IsDate()
  @Type(() => Date)
  lastSessionFrom?: Date | null;

  @ApiPropertyOptional({ example: '2027-02-01T00:00:00.000Z' })
  @IsOptional()
  @IsDate()
  @Type(() => Date)
  lastSessionTo?: Date | null;

  @ApiPropertyOptional({ type: [String], example: ['vi'] })
  @IsOptional()
  @IsArray()
  @ArrayMaxSize(50)
  @IsString({ each: true })
  languages?: string[];

  @ApiPropertyOptional({ type: [String], example: ['VN'] })
  @IsOptional()
  @IsArray()
  @ArrayMaxSize(250)
  @IsString({ each: true })
  countries?: string[];

  @ApiPropertyOptional({ type: [String], example: ['ios'] })
  @IsOptional()
  @IsArray()
  @ArrayMaxSize(4)
  @IsIn(['ios', 'android'], { each: true })
  deviceTypes?: string[];

  @ApiPropertyOptional({
    example: 0,
    description: 'Lifecycle stage lower bound in days since first session (D0…)',
  })
  @IsOptional()
  @IsInt()
  @Min(0)
  @Max(3650)
  lifecycleFrom?: number | null;

  @ApiPropertyOptional({ example: 30 })
  @IsOptional()
  @IsInt()
  @Min(0)
  @Max(3650)
  lifecycleTo?: number | null;

  @ApiPropertyOptional({
    type: [String],
    description: 'Explicit user-id allow-list',
  })
  @IsOptional()
  @IsArray()
  // Generous, but bounded: an unbounded id list is a config document that can
  // grow without limit, and past this size the admin wants a criteria-based
  // segment, not a hand-kept roster.
  @ArrayMaxSize(2000)
  @IsString({ each: true })
  userIds?: string[];

  @ApiPropertyOptional({ type: [Number], example: [1, 2] })
  @IsOptional()
  @IsArray()
  @ArrayMaxSize(100)
  @IsNumber({}, { each: true })
  userGoals?: number[];

  @ApiPropertyOptional({ type: [Number], example: [3] })
  @IsOptional()
  @IsArray()
  @ArrayMaxSize(100)
  @IsNumber({}, { each: true })
  topicIds?: number[];

  @ApiPropertyOptional({
    type: [String],
    example: ['pro_subscription'],
    enum: USER_TYPES,
  })
  @IsOptional()
  @IsArray()
  @ArrayMaxSize(4)
  @IsIn(USER_TYPES as unknown as string[], { each: true })
  userTypes?: string[];
}

export class UpsertSegmentDto {
  @ApiProperty({ example: 'Học viên VN mới, tuần đầu' })
  @IsString()
  @IsNotEmpty()
  @MaxLength(200)
  name: string;

  @ApiPropertyOptional({ type: SegmentCriteriaDto })
  @IsOptional()
  @ValidateNested()
  @Type(() => SegmentCriteriaDto)
  criteria?: SegmentCriteriaDto;
}
