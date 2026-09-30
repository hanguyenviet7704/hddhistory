import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import {
  IsArray,
  IsEnum,
  IsNotEmpty,
  IsNumber,
  IsOptional,
  IsString,
} from 'class-validator';

import {
  FeedbackEntry,
  FeedbackType,
  IncompleteFeedbackReason,
} from '../enum/user-feedback.enum';

export class UpsertUserFeedbackDto {
  @ApiProperty()
  @IsNotEmpty()
  @IsString()
  userId: string;

  @ApiProperty()
  @IsNotEmpty()
  @IsString()
  courseId: string;

  @ApiProperty()
  @IsNotEmpty()
  @IsString()
  lessonId: string;

  @ApiPropertyOptional()
  @IsOptional()
  @IsString()
  keypointId?: string;

  @ApiProperty({ enum: FeedbackType })
  @IsNotEmpty()
  @IsEnum(FeedbackType)
  type: FeedbackType;

  @ApiProperty({ enum: FeedbackEntry })
  @IsNotEmpty()
  @IsEnum(FeedbackEntry)
  entry: FeedbackEntry;

  @ApiPropertyOptional({ example: 5 })
  @IsOptional()
  @IsNumber()
  overallRating?: number;

  @ApiPropertyOptional({ example: 5 })
  @IsOptional()
  @IsNumber()
  contentRating?: number;

  @ApiPropertyOptional({ example: 4 })
  @IsOptional()
  @IsNumber()
  experienceRating?: number;

  @ApiPropertyOptional({ enum: IncompleteFeedbackReason, isArray: true })
  @IsOptional()
  @IsArray()
  @IsEnum(IncompleteFeedbackReason, { each: true })
  reasons?: IncompleteFeedbackReason[];

  @ApiPropertyOptional({ example: 'Great lesson!' })
  @IsOptional()
  @IsString()
  comment?: string;
}
