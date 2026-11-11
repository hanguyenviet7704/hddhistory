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
  ValidateNested,
} from 'class-validator';

import { IsMultiLangString } from '@utils/dto/multi-languge';

import { CourseLevel } from '../enum/course.enum';

class RoadmapNodeDto {
  @ApiPropertyOptional({
    required: false,
    example: '2e7868b5-1fb6-4317-9de7-f06ade57f0cc',
    description: 'unique id of roadmap node',
  })
  @IsOptional()
  @IsString()
  id?: string;

  @ApiProperty({
    type: Object,
    required: true,
    example: { en: 'Roadmap node title', vi: 'Tiêu đề roadmap node' },
  })
  @IsObject()
  @IsNotEmptyObject()
  @IsMultiLangString()
  title: Record<string, string>;

  @ApiPropertyOptional({
    type: Object,
    required: false,
    example: { en: 'Roadmap node description', vi: 'Mô tả roadmap node' },
  })
  @IsOptional()
  @IsObject()
  @IsNotEmptyObject()
  @IsMultiLangString()
  description?: Record<string, string>;

  @ApiPropertyOptional({
    required: false,
    example: '68fe63134a13cd7ab2d5ac5a',
    description: 'id of the opening video lesson',
  })
  @IsOptional()
  @IsString()
  openingVideoId?: string;

  @ApiPropertyOptional({
    required: false,
    example: '68fe63134a13cd7ab2d5ac5a',
    description: 'id of the roleplay',
  })
  @IsOptional()
  @IsString()
  roleplayId?: string;

  @IsArray()
  @ApiPropertyOptional({
    type: [String],
    required: false,
    example: ['68fe63134a13cd7ab2d5ac5a'],
    description: 'ids of the lessons',
  })
  @IsOptional()
  @IsString({ each: true })
  lessonIds: string[];

  @ApiProperty({
    required: false,
    example: '68fe63134a13cd7ab2d5ac5a',
    description: 'id of the lesson',
  })
  @IsOptional()
  @IsString()
  outputId: string;

  @ApiPropertyOptional({
    required: false,
    example: '68fe63134a13cd7ab2d5ac5a',
    description: 'id of the closing video lesson',
  })
  @IsOptional()
  @IsString()
  closingVideoId?: string;
}

export class RoadmapLevelDto {
  @ApiPropertyOptional({
    required: true,
    example: 1,
  })
  @IsNotEmpty()
  @IsNumber()
  id: string;

  @ApiPropertyOptional({
    example: CourseLevel.LEVEL1,
    required: false,
    enum: CourseLevel,
  })
  @IsEnum(CourseLevel)
  @IsNotEmpty()
  level: CourseLevel;

  @ApiPropertyOptional({
    required: false,
    example: 'https://example.com/badge.png',
  })
  @IsOptional()
  @IsString()
  lightBadge: string;

  @ApiProperty({
    type: Object,
    required: true,
    example: { en: 'Lesson Badge', vi: 'Tiêu đề Badge' },
  })
  @IsObject()
  @IsNotEmptyObject()
  @IsMultiLangString()
  titleBadge: Record<string, string>;

  @ApiPropertyOptional({
    required: false,
    example: 'https://example.com/badge.png',
  })
  @IsOptional()
  @IsString()
  darkBadge: string;

  @IsArray()
  @ApiPropertyOptional({
    type: [RoadmapNodeDto],
    example: RoadmapNodeDto,
    required: false,
  })
  @IsOptional()
  @Type(() => RoadmapNodeDto)
  @ValidateNested({ each: true })
  nodes: RoadmapNodeDto[];
}

export class CreateRoadmapDto {
  @IsArray()
  @ApiPropertyOptional({
    type: [RoadmapLevelDto],
    example: RoadmapLevelDto,
    required: false,
  })
  @IsOptional()
  @Type(() => RoadmapLevelDto)
  @ValidateNested({ each: true })
  levels: RoadmapLevelDto[];
}
