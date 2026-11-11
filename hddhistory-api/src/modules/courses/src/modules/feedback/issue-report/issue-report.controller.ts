import {
  Body,
  Controller,
  Delete,
  Get,
  Param,
  Post,
  Query,
  UseGuards,
} from '@nestjs/common';
import { ApiBearerAuth, ApiTags } from '@nestjs/swagger';

import { AuthGuard } from '@base/guard/auth.guard';

import { CreateIssueReportDto } from './dto/create-issue-report.dto';
import { GetIssueReportsDto } from './dto/get-issue-reports.dto';
import { IssueReportService } from './issue-report.service';

@ApiTags('COURSES-REPORTS')
@ApiBearerAuth()
@UseGuards(AuthGuard)
@Controller({ path: 'courses-reports', version: '1' })
export class IssueReportController {
  constructor(private readonly svc: IssueReportService) {}

  @Post('')
  create(@Body() dto: CreateIssueReportDto) {
    return this.svc.create(dto);
  }

  @Get('')
  findAll(@Query() dto: GetIssueReportsDto) {
    return this.svc.getReports(dto);
  }

  @Get(':id')
  findOne(@Param('id') id: string) {
    return this.svc.getReportById(id);
  }

  @Delete(':id')
  remove(@Param('id') id: string) {
    return this.svc.deleteReport(id);
  }
}
