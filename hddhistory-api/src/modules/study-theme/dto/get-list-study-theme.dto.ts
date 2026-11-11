import {
  ApiProperty,
  ApiPropertyOptional,
  IntersectionType,
} from '@nestjs/swagger';
import {
  IsBoolean,
  IsEnum,
  IsNotEmpty,
  IsNumber,
  IsOptional,
  IsString,
} from 'class-validator';

import { ToBoolean } from '@utils/boolean.utils';
import { PageOptionsDto } from '@utils/dto/paging/page.dto';

import { StudyThemeMode } from '../enum/study-theme.enum';

export class GetListStudyThemeDto extends IntersectionType(PageOptionsDto) {
  @ApiProperty({ required: true })
  @IsNotEmpty()
  @IsNumber()
  page: number;

  @ApiProperty({ required: true })
  @IsNotEmpty()
  @IsNumber()
  take: number;

  @ApiPropertyOptional({ enum: StudyThemeMode })
  @IsOptional()
  @IsEnum(StudyThemeMode)
  mode?: StudyThemeMode;

  @ApiPropertyOptional({ example: 'Solid & Gradient' })
  @IsOptional()
  @IsString()
  category?: string;

  @ApiPropertyOptional({
    type: Boolean,
    description: 'Omit to include both active and inactive presets',
  })
  @IsOptional()
  @IsBoolean()
  @ToBoolean()
  isActive?: boolean;
}
