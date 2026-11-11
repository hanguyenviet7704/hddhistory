import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose';
import { SchemaTypes } from 'mongoose';

import { AbstractDocument } from '@base/database/mongodb/abstract.schema';
import { ITranslation } from '@utils/interface/common.interface';

import { IssueReportReason } from '../enum/issue-report.enum';
import { IIssueReport } from '../interface/issue-report.interface';

@Schema({ collection: 'issue_reports' })
export class IssueReport extends AbstractDocument implements IIssueReport {
  @Prop({ required: true })
  userId: string;

  @Prop({ required: true })
  lessonId: string;

  @Prop({ type: SchemaTypes.Mixed })
  lessonTitle?: ITranslation;

  @Prop()
  courseId?: string;

  @Prop({ type: SchemaTypes.Mixed })
  courseTitle?: ITranslation;

  @Prop()
  keypointId?: string;

  @Prop({ type: SchemaTypes.Mixed })
  keypointTitle?: ITranslation;

  @Prop({ type: [String], enum: IssueReportReason, required: true })
  reasons: IssueReportReason[];

  @Prop()
  comment?: string;
}

export const IssueReportSchema = SchemaFactory.createForClass(IssueReport);

IssueReportSchema.index({ userId: 1 });
IssueReportSchema.index({ lessonId: 1 });
IssueReportSchema.index({ courseId: 1 });
