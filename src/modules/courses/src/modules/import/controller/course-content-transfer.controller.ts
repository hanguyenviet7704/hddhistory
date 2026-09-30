import {
  Body,
  Controller,
  Get,
  Param,
  Post,
  Query,
  Req,
  Res,
  UploadedFile,
  UseGuards,
  UseInterceptors,
} from '@nestjs/common';
import { NotFoundException } from '@nestjs/common';
import { FileInterceptor } from '@nestjs/platform-express';
import {
  ApiBearerAuth,
  ApiConsumes,
  ApiOperation,
  ApiTags,
} from '@nestjs/swagger';
import { Request, Response } from 'express';

import { IUserMeta } from '@base/database/mongodb/abstract.interface';
import { CurrentUser } from '@base/decorator/current-user.decorator';
import { AuthGuard } from '@base/guard/auth.guard';

import { CourseRepository } from '../../course/repository/course.repository';
import { ContentSource } from '../../course-version/content-source.service';
import { CourseContentTransferService } from '../course-content-transfer.service';
import { DriveContentSyncService } from '../drive-content-sync.service';

@ApiTags('COURSE-CONTENT-TRANSFERS')
@ApiBearerAuth()
@UseGuards(AuthGuard)
@Controller({ path: 'course-content-transfers', version: '1' })
export class CourseContentTransferController {
  constructor(
    private readonly transferService: CourseContentTransferService,
    private readonly driveSyncService: DriveContentSyncService,
    private readonly contentSource: ContentSource,
    private readonly courseRepository: CourseRepository,
  ) {}

  @Get('template')
  @ApiOperation({
    summary: 'Full-course workbook template (all sheets, ref-key sample rows).',
  })
  async downloadTemplate(@Res() res: Response) {
    const buffer = await this.transferService.buildFullTemplate();
    this.sendExcel(res, buffer, 'course-content-template.xlsx');
  }

  @Post('import')
  @ApiOperation({
    summary:
      'Import a full-course workbook. Always returns the result workbook; validation problems land in an import_errors sheet (X-Import-Errors header carries the count).',
  })
  @ApiConsumes('multipart/form-data')
  @UseInterceptors(FileInterceptor('file'))
  async importCourseContent(
    @UploadedFile() file: Express.Multer.File,
    @Res() res: Response,
    @CurrentUser() user: IUserMeta,
    @Query('autoTag') autoTag?: string,
  ) {
    const result = await this.transferService.importCourseContent(file, {
      autoTag: ['1', 'true', 'yes'].includes(String(autoTag).toLowerCase()),
      actor: user,
    });

    res.setHeader('X-Import-Errors', String(result.errors.length));
    // An import writes the working tree. On a tagged course nothing reaches
    // the app until a tag is made, so say which courses were written and which
    // (if any) were published -- otherwise a sheet editor is left thinking it
    // went live. See `plans/260907-course-content-versions/README.md`.
    res.setHeader(
      'X-Touched-Courses',
      (result.touchedCourseIds ?? []).join(','),
    );
    res.setHeader(
      'X-Auto-Tagged',
      (result.autoTagged ?? []).map(t => `${t.courseId}:${t.tag}`).join(','),
    );
    this.sendExcel(res, result.buffer, 'course-content-result.xlsx');
  }

  @Post('drive-sync')
  @ApiOperation({
    summary:
      'Pull every course sheet in the Drive folder (or one fileId) through the full import and write ids/errors back onto the sheet.',
  })
  async syncFromDrive(@Body() body: { fileId?: string; autoTag?: boolean }) {
    return this.driveSyncService.syncFromDrive(body?.fileId, {
      autoTag: body?.autoTag === true,
    });
  }

  @Post('drive-template')
  @ApiOperation({ summary: 'Create the _TEMPLATE sheet on Drive if missing.' })
  async ensureDriveTemplate() {
    return this.driveSyncService.ensureTemplateOnDrive();
  }

  @Post(':courseId/pull-from-drive')
  @ApiOperation({
    summary:
      "Pull just this course's sheet back through the full import — the per-course half of drive-sync.",
  })
  async pullCourseFromDrive(
    @Param('courseId') courseId: string,
    @Body() body: { autoTag?: boolean },
  ) {
    return this.driveSyncService.pullCourseFromDrive(courseId, {
      autoTag: body?.autoTag === true,
    });
  }

  @Get(':courseId/export')
  @ApiOperation({
    summary:
      'Full workbook for one course (all sheets). ?version=v1.0.0 (or current) exports that frozen tag instead of the working tree; re-importing such a workbook restores it.',
  })
  async exportCourseFull(
    @Param('courseId') courseId: string,
    @Res() res: Response,
    @Req() req: Request,
    @Query('version') version?: string,
  ) {
    const course = await this.courseRepository.findById(courseId);
    if (!course) throw new NotFoundException('course was not found');

    const versionId = await this.contentSource.resolveVersionId(
      course,
      req.headers,
      version,
    );
    const buffer = await this.transferService.exportCourseFull(
      courseId,
      versionId,
    );
    const suffix = versionId && version ? `-${version}` : '';
    this.sendExcel(res, buffer, `course-content-${courseId}${suffix}.xlsx`);
  }

  @Post(':courseId/push-to-drive')
  @ApiOperation({
    summary:
      "Export the course and create/update its Google Sheet in the Drive folder. ?version=v1.0.0 pushes that frozen tag instead of the working tree — the sheet's _VERSION tab says which.",
  })
  async pushCourseToDrive(
    @Param('courseId') courseId: string,
    @Req() req: Request,
    @Query('version') version?: string,
  ) {
    const course = await this.courseRepository.findById(courseId);
    if (!course) throw new NotFoundException('course was not found');

    const versionId = await this.contentSource.resolveVersionId(
      course,
      req.headers,
      version,
    );

    return this.driveSyncService.pushCourseToDrive(courseId, versionId);
  }

  private sendExcel(res: Response, buffer: Buffer, filename: string) {
    res.setHeader(
      'Content-Type',
      'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
    );
    res.setHeader('Content-Disposition', `attachment; filename="${filename}"`);
    res.send(buffer);
  }
}
