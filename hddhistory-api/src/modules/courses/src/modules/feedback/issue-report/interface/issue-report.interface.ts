import { ITranslation } from '@utils/interface/common.interface';

import { IssueReportReason } from '../enum/issue-report.enum';

export interface IIssueReport {
  userId: string;
  lessonId: string;
  lessonTitle?: ITranslation;
  courseId?: string;
  courseTitle?: ITranslation;
  keypointId?: string;
  keypointTitle?: ITranslation;
  reasons: IssueReportReason[];
  comment?: string;
}
