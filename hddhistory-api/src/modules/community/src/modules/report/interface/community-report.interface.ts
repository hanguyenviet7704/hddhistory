import {
  CommunityReportReason,
  CommunityReportStatus,
  CommunityTargetType,
} from '../../../enum/community.enum';

export interface ICommunityReport {
  targetType: CommunityTargetType;
  targetId: string;
  reporterId: string;
  reason: CommunityReportReason;
  note?: string;
  status: CommunityReportStatus;
  resolvedBy?: string;
  resolvedAt?: Date;
}
