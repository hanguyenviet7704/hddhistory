import { ITranslation } from '@utils/interface/common.interface';

import {
  FeedbackEntry,
  FeedbackType,
  IncompleteFeedbackReason,
} from '../enum/user-feedback.enum';

export interface IUserFeedbackComplete {
  courseId: string;
  courseTitle?: ITranslation;
  lessonId: string;
  lessonTitle?: ITranslation;
  keypointId?: string;
  keypointTitle?: ITranslation;
  overallRating: number;
  contentRating: number;
  experienceRating: number;
  comment?: string;
  submittedAt?: Date;
}

export interface IUserFeedbackIncomplete {
  courseId: string;
  courseTitle?: ITranslation;
  lessonId: string;
  lessonTitle?: ITranslation;
  keypointId?: string;
  keypointTitle?: ITranslation;
  reasons?: IncompleteFeedbackReason[];
  comment?: string;
  submittedAt?: Date;
}

/**
 * Resolved filter for the statistics endpoints. Dates are already parsed —
 * the repository never sees raw query strings.
 */
export interface IUserFeedbackStatisticsFilter {
  startDate?: Date;
  endDate?: Date;
  entry?: FeedbackEntry;
  type?: FeedbackType;
}

/** Row shape returned by the metrics aggregation. */
export interface IUserFeedbackMetricsRow {
  records: number;
  users: number;
  complete: number;
  incomplete: number;
  keypoint: number;
  roleplay: number;
  withComment: number;
  averageOverall: number | null;
  averageContent: number | null;
  averageExperience: number | null;
  /** Complete feedback that arrived with no star rating (client sends 0). */
  unrated: number;
}

export interface IUserFeedbackReasonSlice {
  reason: IncompleteFeedbackReason;
  count: number;
}

export interface IUserFeedbackRatingSlice {
  rating: number;
  count: number;
}

export interface IUserFeedbackAbandonedRow {
  entry: FeedbackEntry;
  courseId: string;
  courseTitle?: ITranslation;
  lessonId: string;
  lessonTitle?: ITranslation;
  keypointId?: string;
  keypointTitle?: ITranslation;
  count: number;
  reasons: IncompleteFeedbackReason[];
}

export interface IUserFeedbackDistributions {
  reasons: IUserFeedbackReasonSlice[];
  ratings: IUserFeedbackRatingSlice[];
  topAbandoned: IUserFeedbackAbandonedRow[];
}

/** One embedded slot flattened into a standalone record (see the repository). */
export interface IUserFeedbackRecord {
  userId: string;
  entry: FeedbackEntry;
  type: FeedbackType;
  courseId: string;
  courseTitle?: ITranslation;
  lessonId: string;
  lessonTitle?: ITranslation;
  keypointId?: string;
  keypointTitle?: ITranslation;
  reasons: IncompleteFeedbackReason[];
  overallRating?: number;
  contentRating?: number;
  experienceRating?: number;
  comment?: string;
  submittedAt?: Date;
}

export interface IUserFeedback {
  userId: string;
  roleplayComplete?: IUserFeedbackComplete;
  roleplayIncomplete?: IUserFeedbackIncomplete;
  keypointComplete?: IUserFeedbackComplete;
  keypointIncomplete?: IUserFeedbackIncomplete;
}
