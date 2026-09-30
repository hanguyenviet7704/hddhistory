import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose';
import { SchemaTypes } from 'mongoose';

import { AbstractDocument } from '@base/database/mongodb/abstract.schema';

import { CourseImportJobStatus } from '../enum/course-import-job-status.enum';
import {
  ICourseImportJob,
  ICourseImportJobError,
} from '../interface/course-import-job.interface';

@Schema({ collection: 'course_import_jobs' })
export class CourseImportJob
  extends AbstractDocument
  implements Omit<ICourseImportJob, 'createdBy'>
{
  @Prop({ type: String, required: true })
  createdBy: any;

  @Prop({
    type: String,
    enum: CourseImportJobStatus,
    default: CourseImportJobStatus.QUEUED,
  })
  status: CourseImportJobStatus;

  @Prop({ type: Number, default: 0 })
  totalRows: number;

  @Prop({ type: Number, default: 0 })
  processedRows: number;

  @Prop({ type: Number, default: 0 })
  percent: number;

  @Prop({ type: SchemaTypes.Array, default: [] })
  errors: ICourseImportJobError[];

  @Prop({ type: Date })
  startedAt?: Date;

  @Prop({ type: Date })
  completedAt?: Date;

  @Prop({ type: Date })
  cancelledAt?: Date;

  @Prop({ type: String })
  lastError?: string;
}

export const CourseImportJobSchema =
  SchemaFactory.createForClass(CourseImportJob);

CourseImportJobSchema.index({ createdBy: 1, createdAt: -1 });
CourseImportJobSchema.index({ status: 1, createdAt: -1 });
