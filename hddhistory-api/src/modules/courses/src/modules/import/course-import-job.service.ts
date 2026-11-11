import {
  BadRequestException,
  Injectable,
  Logger,
  NotFoundException,
} from '@nestjs/common';

import { RequestService } from '@base/service/request.service';

import { CourseImportJobStatus } from './enum/course-import-job-status.enum';
import { getRows, getSheet, readWorkbook } from './excel-import.util';
import { ICourseImportJobError } from './interface/course-import-job.interface';
import { CourseImportJobRepository } from './repository/course-import-job.repository';
import { LearningItemService } from '../learning-item/learning-item.service';

import type ExcelJS from 'exceljs';

@Injectable()
export class CourseImportJobService {
  private readonly logger = new Logger(CourseImportJobService.name);

  constructor(
    private readonly courseImportJobRepository: CourseImportJobRepository,
    private readonly learningItemService: LearningItemService,
    private readonly requestService: RequestService,
  ) {}

  async createLearningItemImportJob(file: Express.Multer.File) {
    if (!file?.buffer) {
      throw new BadRequestException('Excel file is required');
    }

    const workbook = await readWorkbook(file);
    this.assertLearningItemSheets(workbook);
    const totalRows = this.countLearningItemRows(workbook);

    const job = await this.courseImportJobRepository.create({
      createdBy: this.getCurrentUserId(),
      status: CourseImportJobStatus.QUEUED,
      totalRows,
      processedRows: 0,
      percent: 0,
      errors: [],
    } as any);

    const buffer = Buffer.from(file.buffer);
    setImmediate(() => {
      this.processLearningItemImportJob(String(job._id), buffer).catch(
        error => {
          this.logger.error(
            `Course import job ${job._id} failed: ${error.message}`,
            error.stack,
          );
        },
      );
    });

    return job;
  }

  async findOne(jobId: string) {
    const job = await this.courseImportJobRepository.findOwnedJob(
      jobId,
      this.getCurrentUserId(),
    );
    if (!job) {
      throw new NotFoundException('Course import job was not found');
    }

    return job;
  }

  private async processLearningItemImportJob(jobId: string, buffer: Buffer) {
    await this.courseImportJobRepository.updateJob(jobId, {
      status: CourseImportJobStatus.PROCESSING,
      startedAt: new Date(),
      lastError: null,
    });

    try {
      const file = this.toMulterFile(buffer);
      const workbook = await readWorkbook(file);
      this.assertLearningItemSheets(workbook);
      const totalRows = this.countLearningItemRows(workbook);
      let processedRows = 0;

      await this.courseImportJobRepository.updateJob(jobId, {
        totalRows,
        processedRows: 0,
        percent: totalRows === 0 ? 100 : 0,
      });

      if (this.hasRows(workbook, 'theories')) {
        await this.learningItemService.importTheories(file);
        processedRows += this.countRows(workbook, 'theories');
        await this.updateProgress(jobId, processedRows, totalRows);
      }

      if (this.hasRows(workbook, 'exercises')) {
        await this.learningItemService.importExercises(file);
        processedRows += this.countRows(workbook, 'exercises');
        await this.updateProgress(jobId, processedRows, totalRows);
      }

      await this.courseImportJobRepository.updateJob(jobId, {
        status: CourseImportJobStatus.COMPLETED,
        processedRows: totalRows,
        percent: 100,
        completedAt: new Date(),
      });
    } catch (error: any) {
      await this.courseImportJobRepository.updateJob(jobId, {
        status: CourseImportJobStatus.FAILED,
        errors: this.resolveImportErrors(error),
        lastError: error?.message || 'Course import failed',
        completedAt: new Date(),
      });
    }
  }

  private resolveImportErrors(error: any): ICourseImportJobError[] {
    const response =
      typeof error?.getResponse === 'function' ? error.getResponse() : null;
    if (response?.errors?.length) {
      return response.errors;
    }

    return [
      {
        sheet: 'workbook',
        row: 0,
        message: error?.message || 'Course import failed',
      },
    ];
  }

  private toMulterFile(buffer: Buffer): Express.Multer.File {
    return {
      buffer,
      originalname: 'learning-item-import.xlsx',
      mimetype:
        'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
      size: buffer.length,
    } as Express.Multer.File;
  }

  private getCurrentUserId() {
    const userId = this.requestService.user?.id;
    if (!userId) {
      throw new BadRequestException('Current user is not available');
    }

    return userId;
  }

  private assertLearningItemSheets(workbook: ExcelJS.Workbook) {
    if (
      !this.hasRows(workbook, 'theories') &&
      !this.hasRows(workbook, 'exercises')
    ) {
      throw new BadRequestException(
        'Workbook must contain theories or exercises sheet',
      );
    }
  }

  private countLearningItemRows(workbook: ExcelJS.Workbook) {
    return (
      this.countRows(workbook, 'theories') +
      this.countRows(workbook, 'exercises')
    );
  }

  private countRows(workbook: ExcelJS.Workbook, sheetName: string) {
    return getRows(getSheet(workbook, [sheetName])).length;
  }

  private hasRows(workbook: ExcelJS.Workbook, sheetName: string) {
    return this.countRows(workbook, sheetName) > 0;
  }

  private async updateProgress(
    jobId: string,
    processedRows: number,
    totalRows: number,
  ) {
    await this.courseImportJobRepository.updateJob(jobId, {
      processedRows,
      percent:
        totalRows === 0 ? 100 : Math.round((processedRows / totalRows) * 100),
    });
  }
}
