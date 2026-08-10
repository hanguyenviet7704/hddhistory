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

export interface ILessonSection {
  title: string;
  blocks: ILessonBlock[];
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
    sections: ILessonSection[];
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
