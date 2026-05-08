export type DriveImportJobStatus =
  | "queued"
  | "processing"
  | "completed"
  | "completed_with_errors"
  | "failed"
  | "cancelled";

export interface DriveImportUploadedItem {
  path: string;
  url: string;
  uploadedAt: string;
}

export interface DriveImportFailedFile {
  path: string;
  message: string;
  failedAt: string;
}

export interface DriveImportJob {
  _id: string;
  createdBy: string;
  folderUrl: string;
  status: DriveImportJobStatus;
  totalFiles: number;
  uploadedFiles: number;
  failedCount: number;
  percent: number;
  uploadedItems: DriveImportUploadedItem[];
  failedFiles: DriveImportFailedFile[];
  startedAt?: string;
  completedAt?: string;
  cancelledAt?: string;
  lastError?: string;
  createdAt: string;
  updatedAt: string;
}
