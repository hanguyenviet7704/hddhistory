import { Body, Controller, Get, Param, Post, Query, UseGuards } from '@nestjs/common';
import { ApiBearerAuth, ApiOperation, ApiTags } from '@nestjs/swagger';

import { AuthGuard } from '@base/guard/auth.guard';

import { CreateLearningImportDto } from './dto/create-learning-import.dto';
import { ListUserLessonDto } from './dto/list-learning-import.dto';
import { LearningImportService } from './learning-import.service';

@ApiTags('LEARNING-IMPORTS')
@ApiBearerAuth()
@UseGuards(AuthGuard)
@Controller({ path: 'learning-imports', version: '1' })
export class LearningImportController {
  constructor(private readonly svc: LearningImportService) {}

  @ApiOperation({
    summary: 'Start generating a lesson from a PDF or a YouTube link',
    description:
      'Returns immediately with a job; poll GET /learning-imports/:jobId for progress. ' +
      'A PDF must already be uploaded via POST /cloudflares/upload -- send its object key, not the file.',
  })
  @Post('')
  create(@Body() dto: CreateLearningImportDto) {
    return this.svc.create(dto);
  }

  @ApiOperation({
    summary: 'Imports the caller has left',
    description:
      'Shown before the user commits to an import. A subscriber gets a weekly allowance and `resetsAt` names next Monday 00:00; a free reader gets ONE ticket for the lifetime of the account and `resetsAt` is null -- there is no refill.',
  })
  @Get('quota')
  getQuota() {
    return this.svc.getQuota();
  }

  @ApiOperation({ summary: "The caller's own import history" })
  @Get('')
  list(@Query() dto: ListUserLessonDto) {
    return this.svc.listJobs(dto);
  }

  // Declared last: `quota` above would otherwise be swallowed by this param
  // route and every quota call would 404 looking for a job with that id.
  @ApiOperation({
    summary: 'Progress of one import',
    description:
      'Status may come back `interrupted` -- the run died (deploy, crash) and can be retried. It did not consume a quota slot.',
  })
  @Get(':jobId')
  getJob(@Param('jobId') jobId: string) {
    return this.svc.getJob(jobId);
  }
}
