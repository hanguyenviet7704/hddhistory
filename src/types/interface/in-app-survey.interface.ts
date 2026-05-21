import { ITranslation } from "../../utils/translate";

export enum InAppSurveyClosedQuestionType {
  SINGLE_CHOICE = "single_choice",
  MULTIPLE_CHOICE = "multiple_choice",
}

export interface IInAppSurveyQuestion {
  question: ITranslation;
  guide?: ITranslation;
}

export interface IInAppSurveyEmoji {
  name?: string;
  darkUrl: string;
  lightUrl?: string;
}

export interface IInAppSurveyOption {
  id: string;
  icon: string;
  value: ITranslation;
}

export interface IInAppSurveyClosedQuestion extends IInAppSurveyQuestion {
  type: InAppSurveyClosedQuestionType;
  options: IInAppSurveyOption[];
}

export interface IInAppSurveyBranch {
  id: string;
  emoji: IInAppSurveyEmoji;
  closedQuestion: IInAppSurveyClosedQuestion;
  openQuestion: IInAppSurveyQuestion;
  index: number;
  score?: number;
}

export interface IInAppSurveyConfig {
  _id?: string;
  configKey?: string;
  introQuestion: IInAppSurveyQuestion;
  branches: IInAppSurveyBranch[];
  createdAt?: string;
  updatedAt?: string;
}

export type InAppSurveyOptionPayload = Partial<IInAppSurveyOption> &
  Pick<IInAppSurveyOption, "icon" | "value">;

export interface InAppSurveyClosedQuestionPayload
  extends IInAppSurveyQuestion {
  type: InAppSurveyClosedQuestionType;
  options: InAppSurveyOptionPayload[];
}

export interface InAppSurveyBranchPayload {
  id?: string;
  emoji: IInAppSurveyEmoji;
  closedQuestion: InAppSurveyClosedQuestionPayload;
  openQuestion: IInAppSurveyQuestion;
  index?: number;
  score?: number;
}

export interface InAppSurveyConfigPayload {
  introQuestion: IInAppSurveyQuestion;
  branches: InAppSurveyBranchPayload[];
}

export interface IInAppSurveyResponseBranch {
  emoji: IInAppSurveyEmoji;
  closedQuestion: Omit<IInAppSurveyClosedQuestion, "options">;
  openQuestion: IInAppSurveyQuestion;
}

export interface IInAppSurveyResponse {
  _id: string;
  userId: string;
  userSnapshot?: IInAppSurveyUserSnapshot | null;
  branchId: string;
  branchIndex?: number;
  branchName?: string;
  ratingScore?: number;
  introQuestion: IInAppSurveyQuestion;
  branch: IInAppSurveyResponseBranch;
  selectedOptions: IInAppSurveyOption[];
  feedback?: string;
  submittedAt?: string;
  completedAt?: string;
  createdAt?: string;
  updatedAt?: string;
}

export interface IInAppSurveyUserSnapshot {
  name?: string;
  email?: string;
  avatar?: string;
}

export interface InAppSurveyResponseListParams {
  page: number;
  take: number;
  userId?: string;
}

export interface InAppSurveyResponseListResult {
  items: IInAppSurveyResponse[];
  total: number;
  totalPages: number;
  currentPage: number;
  itemsPerPage: number;
}

export interface InAppSurveyDateRangeParams {
  startDate?: string;
  endDate?: string;
}

export interface InAppSurveyMetricValue {
  value: number;
  delta: number;
}

export interface InAppSurveyRatingDistributionItem {
  branchId: string;
  branchIndex?: number;
  branchName?: string;
  ratingScore: number;
  emoji?: IInAppSurveyEmoji;
  count: number;
  percent: number;
}

export interface InAppSurveyOptionDistributionItem {
  option: IInAppSurveyOption;
  count: number;
  percent: number;
}

export interface InAppSurveyBranchSummary
  extends InAppSurveyRatingDistributionItem {
  closedQuestion?: Omit<IInAppSurveyClosedQuestion, "options">;
  openQuestion?: IInAppSurveyQuestion;
  options: InAppSurveyOptionDistributionItem[];
  feedbacks: Pick<
    IInAppSurveyResponse,
    "_id" | "feedback" | "submittedAt" | "selectedOptions"
  >[];
}

export interface InAppSurveyStatisticsOverview {
  metrics: {
    totalResponses: InAppSurveyMetricValue;
    averageRating: InAppSurveyMetricValue;
    completionRate: InAppSurveyMetricValue;
    responseRate: InAppSurveyMetricValue;
  };
  ratingDistribution: InAppSurveyRatingDistributionItem[];
  branches: InAppSurveyBranchSummary[];
}

export interface InAppSurveyBranchResponsesResult
  extends InAppSurveyResponseListResult {
  branch: {
    branchId: string;
    branchIndex?: number;
    branchName?: string;
    ratingScore: number;
    emoji?: IInAppSurveyEmoji;
    closedQuestion?: Omit<IInAppSurveyClosedQuestion, "options">;
    openQuestion?: IInAppSurveyQuestion;
  } | null;
  optionFilters: {
    option: IInAppSurveyOption;
    count: number;
  }[];
}

export interface InAppSurveyUserResponsesResult
  extends InAppSurveyResponseListResult {
  branchFilters: InAppSurveyRatingDistributionItem[];
  distinctUsers: number;
}

export interface InAppSurveyExportRow {
  user_id: string;
  user_name: string | null;
  user_email: string | null;
  emoji_level: number;
  emoji_name: string;
  selected_options: string;
  feedback: string;
  submitted_at: string;
}
