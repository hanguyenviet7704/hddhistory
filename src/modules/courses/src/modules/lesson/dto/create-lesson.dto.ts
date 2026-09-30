import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { Type } from 'class-transformer';
import {
  IsArray,
  IsEnum,
  IsNotEmpty,
  IsNotEmptyObject,
  IsNumber,
  IsObject,
  IsOptional,
  IsString,
  Min,
  ValidateIf,
  ValidateNested,
} from 'class-validator';

import { IsMultiLangString } from '@utils/dto/multi-languge';

import { LessonStatus, LessonType } from '../enum/lesson.enum';

export class LessonVideoDto {
  @ApiProperty({
    example: 'https://example.com/video.mp4',
    required: true,
    description: 'Video source url.',
  })
  @ValidateIf(o => o.url !== undefined || o.thumbnail !== undefined)
  @IsNotEmpty()
  @IsString()
  url?: string;

  @ApiPropertyOptional({
    example: 'https://example.com/video-thumbnail.jpg',
    required: false,
    description: 'Thumbnail image url for video lesson.',
  })
  @IsOptional()
  @IsString()
  thumbnail?: string;

  @ApiPropertyOptional({
    type: Object,
    required: false,
    example: { en: '<p>Video summary</p>', vi: '<p>Tom tat video</p>' },
    description: 'Video summary as localized HTML text.',
  })
  @IsObject()
  @IsOptional()
  @IsMultiLangString()
  summary?: Record<string, string>;
}

export class CreateLessonDto {
  @ApiProperty({
    type: Object,
    required: true,
    example: { en: 'Lesson title', vi: 'Tiêu đề bài học' },
  })
  @IsObject()
  @IsNotEmptyObject()
  @IsMultiLangString()
  title: Record<string, string>;

  @ApiProperty({
    required: true,
    example: '68fe63134a13cd7ab2d5ac5a',
    description: 'Course id',
  })
  @IsNotEmpty()
  @IsString()
  courseId: string;

  @ApiProperty({
    required: false,
    example: '68fe63134a13cd7ab2d5ac5a',
    description: 'learningItem id',
  })
  @IsOptional()
  @IsString()
  learningItemId: string;

  @ApiProperty({
    enum: LessonType,
    example: LessonType.ROLEPLAY,
    required: true,
  })
  @IsNotEmpty()
  @IsEnum(LessonType)
  type: LessonType;

  @ApiPropertyOptional({
    type: Object,
    required: false,
    example: { en: 'Lesson Description', vi: 'Mô tả bài học' },
  })
  @IsObject()
  @IsOptional()
  @IsMultiLangString()
  description: Record<string, string>;

  @ApiPropertyOptional({ example: 'https://example.com', required: false })
  @IsString()
  @IsOptional()
  image: string;

  @ApiPropertyOptional({
    type: LessonVideoDto,
    required: false,
    description: 'Video payload. Required when lesson type is video.',
  })
  @ValidateIf(o => o.type === LessonType.VIDEO || o.video !== undefined)
  @IsObject()
  @IsNotEmptyObject()
  @ValidateNested()
  @Type(() => LessonVideoDto)
  video?: LessonVideoDto;

  @ApiPropertyOptional({
    enum: LessonStatus,
    example: LessonStatus.PUBLISHED,
    required: false,
  })
  @IsOptional()
  @IsEnum(LessonStatus)
  status?: LessonStatus;

  @IsArray()
  @ApiPropertyOptional({
    type: [String],
    example: ['68fe63134a13cd7ab2d5ac5a'],
    required: false,
    description: 'keypoint ids',
  })
  @IsOptional()
  @IsString({ each: true })
  keypoints: string[];

  @ApiPropertyOptional({
    type: Object,
    required: false,
    example: { en: '1 hours', vi: '1 giờ' },
  })
  @IsObject()
  @IsOptional()
  @IsMultiLangString()
  estimateCompleTime: Record<string, string>;

  @ApiPropertyOptional({
    required: false,
    example: 8,
    description:
      'Estimated completion time in minutes. Used as source-of-truth for calculations.',
  })
  @IsOptional()
  @IsNumber()
  @Min(0)
  estimateCompleTimeNumber: number;

  @ApiPropertyOptional({ required: false, example: 'https://example.com' })
  @IsOptional()
  @IsString()
  icon: string;

  @ApiPropertyOptional({ required: false, example: 'https://example.com' })
  @IsOptional()
  @IsString()
  lightIcon: string;

  @ApiPropertyOptional({
    required: false,
    example: 'assistant=v2;temperature=0.3',
  })
  @IsOptional()
  @IsString()
  AIConfig: string;

  @ApiPropertyOptional({
    required: false,
    example: '68fe63134a13cd7ab2d5ac5a',
  })
  @IsOptional()
  @IsString()
  animation: string;

  @ApiProperty({ required: false, example: 1 })
  @IsOptional()
  @IsNumber()
  index: number;
}
