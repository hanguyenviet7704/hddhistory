import { CourseImportJobStatus } from '../enum/course-import-job-status.enum';

export interface ICourseImportJobError {
  sheet: string;
  row: number;
  column?: string;
  message: string;
}

export interface ICourseImportJob {
  createdBy: string;
  status: CourseImportJobStatus;
  totalRows: number;
  processedRows: number;
  percent: number;
  errors: ICourseImportJobError[];
  startedAt?: Date;
  completedAt?: Date;
  cancelledAt?: Date;
  lastError?: string;
}
