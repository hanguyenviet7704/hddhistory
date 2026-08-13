export type ImportJobStatus =
  | "queued"
  | "processing"
  | "completed"
  | "failed"
  // Derived server-side from a stale heartbeat, never stored: the process
  // running the job died (deploy, crash) and nothing was left to write a final
  // status. Cannot be used as a filter value for that reason.
  | "interrupted";

export type ImportSourceType = "pdf" | "youtube";

export interface ILearningImportSource {
  type: ImportSourceType;
  fileKey?: string;
  fileName?: string;
  pageCount?: number;
  url?: string;
  videoTitle?: string;
  videoDurationSeconds?: number;
}

export interface ILearningImportUsage {
  inputTokens: number;
  outputTokens: number;
  estimatedCostVnd: number;
}

export interface ILearningImportRow {
  id: string;
  userId: string;
  status: ImportJobStatus;
  stage: string | null;
  percent: number;
  sourceType: ImportSourceType;
  sourceLabel: string;
  source: ILearningImportSource;
  outputLocale: string;
  userLessonId: string | null;
  errorCode: string | null;
  errorMessage: string | null;
  usage: ILearningImportUsage | null;
  createdAt: string;
  completedAt: string | null;
}

export interface ILessonBlock {
  type: "heading" | "paragraph";
  text: string;
}

/** One card in the reader. Named "section" from when a lesson was a flat list. */
export interface ILessonSection {
  title: string;
  blocks: ILessonBlock[];
}

/**
 * A group of cards the learner finishes in one sitting — the same unit a
 * catalogue keypoint is. How many a lesson has is the model's call, so the admin
 * shows the division rather than assuming a number.
 */
export interface ILessonKeypoint {
  title: string;
  sections: ILessonSection[];
}

export interface ILearningImportDetail extends ILearningImportRow {
  startedAt: string | null;
  heartbeatAt: string | null;
  // The generated lesson. Null when the run failed before saving, or when the
  // user has since deleted it.
  lesson: {
    id: string;
    title: string;
    description: string;
    wordCount: number;
    estimatedMinutes: number;
    keypoints: ILessonKeypoint[];
  } | null;
}

export interface LearningImportListQuery {
  page?: number;
  take?: number;
  status?: Exclude<ImportJobStatus, "interrupted">;
  search?: string;
}

export interface LearningImportListResponse {
  items: ILearningImportRow[];
  itemsPerPage: number;
  totalPages: number;
  currentPage: number;
}

/** Body for POST /learning-imports. Exactly one of fileKey / url is used. */
export interface CreateLearningImportPayload {
  sourceType: ImportSourceType;
  /** R2 object key from POST /cloudflares/upload — NOT the public url. */
  fileKey?: string;
  fileName?: string;
  url?: string;
  outputLocale: string;
}

export interface ImportQuota {
  limit: number;
  used: number;
  remaining: number;
  resetsAt: string;
  isPremium: boolean;
  /** What the premium allowance would be — the number the app's upsell quotes. */
  premiumLimit?: number;
  /** The feature switch, folded into this call so the app learns both at once. */
  enabled?: boolean;
  disabledNote?: string;
}

/** What the import feature has actually done. GET /admin/learning-imports/stats. */
export interface ILearningImportStats {
  totalJobs: number;
  jobsLast7Days: number;
  completedJobs: number;
  failedJobs: number;
  runningJobs: number;
  /** Completed / (completed + failed). Unfinished jobs are excluded — they are
   *  not evidence either way. */
  successRate: number;
  uniqueUsers: number;
  /** Estimated, not billed — the runner's own cost figure. */
  totalCostVnd: number;
  averageCostVnd: number;
  totalLessons: number;
  byStatus: { status: string; count: number }[];
  bySource: { sourceType: string; count: number }[];
  topErrors: { code: string; count: number }[];
}

/** GET/PUT /admin/learning-imports/config. */
export interface ILearningImportConfig {
  enabled: boolean;
  disabledNote: string;
  /**
   * Admin-curated pool of LESSON cover images (R2 urls). A lesson is dealt one
   * at creation and keeps it — pool edits only affect lessons born after them.
   * Separate from the keypoint pool on purpose: different kind of picture.
   */
  courseCoverUrls: string[];
  /** Pool for the roadmap's keypoint-node thumbnails. Same lifecycle rules. */
  keypointImageUrls: string[];
}
