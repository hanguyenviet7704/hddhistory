import { ITranslation } from "../../utils/translate";
import {
  FeedbackEntry,
  FeedbackType,
  IncompleteFeedbackReason,
} from "../enum/feedback.enum";

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

export interface IUserFeedback {
  userId: string;
  roleplayComplete?: IUserFeedbackComplete;
  roleplayIncomplete?: IUserFeedbackIncomplete;
  keypointComplete?: IUserFeedbackComplete;
  keypointIncomplete?: IUserFeedbackIncomplete;
}

// ---------------------------------------------------------------------------
// Analytics
// ---------------------------------------------------------------------------

/** Query shared by the overview and the comment list. */
export interface IUserFeedbackStatisticsQuery {
  startDate?: string;
  endDate?: string;
  entry?: FeedbackEntry;
  type?: FeedbackType;
}

/**
 * `delta` is null when the request had no explicit window — there is no
 * previous period to compare an all-time figure against.
 */
export interface IUserFeedbackMetric {
  value: number | null;
  delta?: number | null;
}

export interface IUserFeedbackReasonSlice {
  reason: IncompleteFeedbackReason;
  count: number;
  percent: number;
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
  /** The reasons behind this row, most common first (max 3). */
  topReasons: IUserFeedbackReasonSlice[];
}

export interface IUserFeedbackStatisticsOverview {
  range: {
    startDate?: string;
    endDate?: string;
    previousStartDate?: string;
    previousEndDate?: string;
  };
  /**
   * Always true today: the collection keeps one document per user with a
   * single slot per (entry, type), so every count is "users whose LATEST
   * feedback looks like this", never a count of submissions. The page prints
   * this rather than letting a reader assume event counts.
   */
  perUserLatestOnly: boolean;
  metrics: {
    records: IUserFeedbackMetric;
    users: IUserFeedbackMetric;
    complete: IUserFeedbackMetric;
    incomplete: IUserFeedbackMetric;
    keypoint: IUserFeedbackMetric;
    roleplay: IUserFeedbackMetric;
    withComment: IUserFeedbackMetric;
    /** Complete feedback with no star rating — the client sends 0 for those. */
    unrated: IUserFeedbackMetric;
    averageOverall: IUserFeedbackMetric;
    averageContent: IUserFeedbackMetric;
    averageExperience: IUserFeedbackMetric;
  };
  reasonDistribution: IUserFeedbackReasonSlice[];
  ratingDistribution: IUserFeedbackRatingSlice[];
  topAbandoned: IUserFeedbackAbandonedRow[];
}

export interface IUserFeedbackCommentRow {
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
  submittedAt?: string;
}

export interface IUserFeedbackCommentPage {
  items: IUserFeedbackCommentRow[];
  currentPage: number;
  itemsPerPage: number;
  totalPages: number;
  totalItems: number;
}
