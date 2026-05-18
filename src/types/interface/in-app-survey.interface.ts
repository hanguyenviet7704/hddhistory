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
  branchId: string;
  introQuestion: IInAppSurveyQuestion;
  branch: IInAppSurveyResponseBranch;
  selectedOptions: IInAppSurveyOption[];
  feedback?: string;
  submittedAt?: string;
  createdAt?: string;
  updatedAt?: string;
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
