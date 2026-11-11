import { ApiPropertyOptional, IntersectionType } from '@nestjs/swagger';
import { Type } from 'class-transformer';
import {
  IsDateString,
  IsIn,
  IsNumber,
  IsOptional,
  IsString,
} from 'class-validator';

import { PageOptionsDto } from '@utils/dto/paging/page.dto';
import { OrderType } from '@utils/type/orderByType';

export class InAppSurveyDateRangeDto {
  @ApiPropertyOptional({
    description: 'Start date for statistics.',
    example: '2026-04-21T00:00:00.000Z',
  })
  @IsOptional()
  @IsDateString()
  startDate?: string;

  @ApiPropertyOptional({
    description: 'End date for statistics.',
    example: '2026-05-21T23:59:59.999Z',
  })
  @IsOptional()
  @IsDateString()
  endDate?: string;
}

export class GetInAppSurveyBranchResponsesDto extends IntersectionType(
  PageOptionsDto,
  InAppSurveyDateRangeDto,
) {
  @ApiPropertyOptional({
    description: 'Selected Q2 option id.',
  })
  @IsOptional()
  @IsString()
  optionId?: string;
}

export class GetInAppSurveyUserResponsesDto extends IntersectionType(
  PageOptionsDto,
  InAppSurveyDateRangeDto,
) {
  @ApiPropertyOptional({
    description: 'Selected branch id.',
  })
  @IsOptional()
  @IsString()
  branchId?: string;

  @ApiPropertyOptional({
    enum: OrderType,
    default: OrderType.DESC,
  })
  @IsOptional()
  @IsIn([OrderType.ASC, OrderType.DESC])
  order?: OrderType = OrderType.DESC;
}

export class ExportInAppSurveyResponsesDto extends InAppSurveyDateRangeDto {
  @ApiPropertyOptional({
    description: 'Selected branch id.',
  })
  @IsOptional()
  @IsString()
  branchId?: string;

  @ApiPropertyOptional({
    description: 'Language code used to flatten translated values.',
    example: 'vi',
  })
  @IsOptional()
  @IsString()
  lang?: string;
}

export class StartInAppSurveySessionDto {
  @ApiPropertyOptional({
    description: 'Optional client timestamp for when Q1 was shown.',
  })
  @IsOptional()
  @IsDateString()
  startedAt?: string;
}

export class GetInAppSurveyDateRangePageDto extends InAppSurveyDateRangeDto {
  @ApiPropertyOptional({ default: 1 })
  @IsOptional()
  @Type(() => Number)
  @IsNumber()
  page?: number = 1;

  @ApiPropertyOptional({ default: 20 })
  @IsOptional()
  @Type(() => Number)
  @IsNumber()
  take?: number = 20;
}
