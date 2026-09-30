import { DriveImportJobStatus } from '../enum/drive-import-job-status.enum';

export interface IDriveImportUploadedItem {
  path: string;
  url: string;
  uploadedAt: Date;
}

export interface IDriveImportFailedFile {
  path: string;
  message: string;
  failedAt: Date;
}

export interface IDriveImportJob {
  id?: string;
  createdBy: string;
  folderUrl: string;
  status: DriveImportJobStatus;
  totalFiles: number;
  uploadedFiles: number;
  failedCount: number;
  percent: number;
  uploadedItems: IDriveImportUploadedItem[];
  failedFiles: IDriveImportFailedFile[];
  startedAt?: Date;
  completedAt?: Date;
  cancelledAt?: Date;
  lastError?: string;
}
