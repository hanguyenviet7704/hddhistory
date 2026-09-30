import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import {
  IsEnum,
  IsMongoId,
  IsNotEmpty,
  IsNotEmptyObject,
  IsNumber,
  IsObject,
  IsOptional,
} from 'class-validator';

import { IsMultiLangString } from '@utils/dto/multi-languge';

import { ReanchorReasonStatus } from '../enum/reanchor-reason.enum';

export class CreateReanchorReasonDto {
  @ApiProperty({
    required: true,
    description: 'Course this re-anchor reason belongs to',
  })
  @IsNotEmpty()
  @IsMongoId()
  courseId: string;

  @ApiProperty({
    type: Object,
    required: true,
    example: { en: 'I lost motivation', vi: 'Tôi mất động lực' },
  })
  @IsObject()
  @IsNotEmptyObject()
  @IsMultiLangString()
  reason: Record<string, string>;

  @ApiPropertyOptional({ example: 0, description: 'Sort order' })
  @IsOptional()
  @IsNumber()
  order?: number;

  @ApiPropertyOptional({
    enum: ReanchorReasonStatus,
    example: ReanchorReasonStatus.PUBLISHED,
  })
  @IsOptional()
  @IsEnum(ReanchorReasonStatus)
  status?: ReanchorReasonStatus;
}
