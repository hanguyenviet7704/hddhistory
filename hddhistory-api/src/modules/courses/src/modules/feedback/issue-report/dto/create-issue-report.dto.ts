import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import {
  IsArray,
  IsEnum,
  IsNotEmpty,
  IsOptional,
  IsString,
  ArrayNotEmpty,
} from 'class-validator';

import { IssueReportReason } from '../enum/issue-report.enum';

export class CreateIssueReportDto {
  @ApiProperty({ description: 'ID of the lesson being reported' })
  @IsNotEmpty()
  @IsString()
  lessonId: string;

  @ApiPropertyOptional({ description: 'Optional course ID of the lesson' })
  @IsOptional()
  @IsString()
  courseId?: string;

  @ApiPropertyOptional({ description: 'Optional keypoint ID being reported' })
  @IsOptional()
  @IsString()
  keypointId?: string;

  @ApiProperty({ enum: IssueReportReason, isArray: true, description: 'Selected reasons for reporting the issue' })
  @IsArray()
  @ArrayNotEmpty()
  @IsEnum(IssueReportReason, { each: true })
  reasons: IssueReportReason[];

  @ApiPropertyOptional({ example: 'Describe the issue so we can fix it faster', description: 'Additional description of the issue' })
  @IsOptional()
  @IsString()
  comment?: string;
}
