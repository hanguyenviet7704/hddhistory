import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose';

import { AbstractDocument } from '@base/database/mongodb/abstract.schema';

import {
  CommunityReportReason,
  CommunityReportStatus,
  CommunityTargetType,
} from '../../../enum/community.enum';
import { ICommunityReport } from '../interface/community-report.interface';

@Schema({ collection: 'community_reports' })
export class CommunityReport
  extends AbstractDocument
  implements ICommunityReport
{
  @Prop({ type: String, enum: CommunityTargetType, required: true })
  targetType: CommunityTargetType;

  @Prop({ required: true })
  targetId: string;

  @Prop({ required: true })
  reporterId: string;

  @Prop({ type: String, enum: CommunityReportReason, required: true })
  reason: CommunityReportReason;

  @Prop()
  note?: string;

  @Prop({
    type: String,
    enum: CommunityReportStatus,
    default: CommunityReportStatus.PENDING,
  })
  status: CommunityReportStatus;

  @Prop()
  resolvedBy?: string;

  @Prop()
  resolvedAt?: Date;
}

export const CommunityReportSchema =
  SchemaFactory.createForClass(CommunityReport);

// One reader reports a given item once. A second attempt is a no-op, not a
// second row inflating reportCount.
CommunityReportSchema.index(
  { targetType: 1, targetId: 1, reporterId: 1 },
  { unique: true },
);
CommunityReportSchema.index({ status: 1, createdAt: -1 });
