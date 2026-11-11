import {
  Controller,
  Get,
  Param,
  Post,
  UploadedFile,
  UseGuards,
  UseInterceptors,
} from '@nestjs/common';
import { FileInterceptor } from '@nestjs/platform-express';
import { ApiBearerAuth, ApiConsumes, ApiTags } from '@nestjs/swagger';

import { AuthGuard } from '@base/guard/auth.guard';

import { CourseImportJobService } from '../course-import-job.service';

@ApiTags('COURSE-IMPORT-JOBS')
@ApiBearerAuth()
@UseGuards(AuthGuard)
@Controller({ path: 'course-import-jobs', version: '1' })
export class CourseImportJobController {
  constructor(private readonly courseImportJobService: CourseImportJobService) {}

  @Post('learning-items')
  @ApiConsumes('multipart/form-data')
  @UseInterceptors(FileInterceptor('file'))
  createLearningItemImportJob(@UploadedFile() file: Express.Multer.File) {
    return this.courseImportJobService.createLearningItemImportJob(file);
  }

  @Get(':jobId')
  findOne(@Param('jobId') jobId: string) {
    return this.courseImportJobService.findOne(jobId);
  }
}
