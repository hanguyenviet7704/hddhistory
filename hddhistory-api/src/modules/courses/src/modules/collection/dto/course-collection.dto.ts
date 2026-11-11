import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { Transform } from 'class-transformer';
import {
  ArrayMaxSize,
  IsArray,
  IsEnum,
  IsInt,
  IsNotEmptyObject,
  IsObject,
  IsOptional,
  IsString,
  Min,
} from 'class-validator';

import { IsMultiLangString } from '@utils/dto/multi-languge';

import { EXPLORE_COLLECTION_SIZE } from '../../explore/explore.constant';

import {
  CourseCollectionSlot,
  CourseCollectionStatus,
} from '../enum/course-collection.enum';

export class CreateCourseCollectionDto {
  @ApiProperty({
    type: Object,
    example: { en: 'Good places to start', vi: 'Phù hợp để bắt đầu' },
  })
  @IsObject()
  @IsNotEmptyObject()
  @IsMultiLangString()
  title: Record<string, string>;

  @ApiPropertyOptional({ enum: CourseCollectionStatus })
  @IsOptional()
  @IsEnum(CourseCollectionStatus)
  status?: CourseCollectionStatus;

  @ApiPropertyOptional({ enum: CourseCollectionSlot })
  @IsOptional()
  @IsEnum(CourseCollectionSlot)
  slot?: CourseCollectionSlot;

  @ApiPropertyOptional({ type: Number, example: 0 })
  @IsOptional()
  @IsInt()
  @Min(0)
  index?: number;

  @ApiPropertyOptional({ type: [String] })
  @IsOptional()
  @IsArray()
  @IsString({ each: true })
  segmentIds?: string[];

  @ApiPropertyOptional({
    type: [String],
    description: `At most ${EXPLORE_COLLECTION_SIZE} courses — the strip shows the whole collection, so a longer list would simply never be seen.`,
  })
  @IsOptional()
  @IsArray()
  @IsString({ each: true })
  @ArrayMaxSize(EXPLORE_COLLECTION_SIZE)
  courseIds?: string[];
}

export class UpdateCourseCollectionDto extends CreateCourseCollectionDto {
  @ApiPropertyOptional({
    type: Object,
    example: { en: 'Good places to start', vi: 'Phù hợp để bắt đầu' },
  })
  @IsObject()
  @IsOptional()
  @IsMultiLangString()
  declare title: Record<string, string>;
}

export class GetListCourseCollectionDto {
  @ApiPropertyOptional({ enum: CourseCollectionStatus })
  @IsOptional()
  @IsEnum(CourseCollectionStatus)
  status?: CourseCollectionStatus;

  @ApiPropertyOptional({ enum: CourseCollectionSlot })
  @IsOptional()
  @IsEnum(CourseCollectionSlot)
  slot?: CourseCollectionSlot;
}

/**
 * Admin drag-and-drop reorder: the whole slot's order arrives at once rather
 * than one index per request, so a reorder is a single atomic write and cannot
 * leave two rows sharing an index halfway through.
 */
export class ReorderCourseCollectionDto {
  @ApiProperty({ type: [String] })
  @IsArray()
  @IsString({ each: true })
  @Transform(({ value }) => (Array.isArray(value) ? value : []))
  ids: string[];
}
