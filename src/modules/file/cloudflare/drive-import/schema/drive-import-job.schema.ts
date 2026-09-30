import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose';
import { SchemaTypes } from 'mongoose';

import { AbstractDocument } from '@base/database/mongodb/abstract.schema';

import { DriveImportJobStatus } from '../enum/drive-import-job-status.enum';
import {
  IDriveImportFailedFile,
  IDriveImportJob,
  IDriveImportUploadedItem,
} from '../interface/drive-import-job.interface';

@Schema({ collection: 'drive_import_jobs' })
export class DriveImportJob
  extends AbstractDocument
  implements Omit<IDriveImportJob, 'createdBy'>
{
  @Prop({ type: String, required: true })
  createdBy: any;

  @Prop({ type: String, required: true })
  folderUrl: string;

  @Prop({
    type: String,
    enum: DriveImportJobStatus,
    default: DriveImportJobStatus.QUEUED,
  })
  status: DriveImportJobStatus;

  @Prop({ type: Number, default: 0 })
  totalFiles: number;

  @Prop({ type: Number, default: 0 })
  uploadedFiles: number;

  @Prop({ type: Number, default: 0 })
  failedCount: number;

  @Prop({ type: Number, default: 0 })
  percent: number;

  @Prop({ type: SchemaTypes.Array, default: [] })
  uploadedItems: IDriveImportUploadedItem[];

  @Prop({ type: SchemaTypes.Array, default: [] })
  failedFiles: IDriveImportFailedFile[];

  @Prop({ type: Date })
  startedAt?: Date;

  @Prop({ type: Date })
  completedAt?: Date;

  @Prop({ type: Date })
  cancelledAt?: Date;

  @Prop({ type: String })
  lastError?: string;
}

export const DriveImportJobSchema =
  SchemaFactory.createForClass(DriveImportJob);

DriveImportJobSchema.index({ createdBy: 1, status: 1 });
DriveImportJobSchema.index({ createdAt: -1 });
