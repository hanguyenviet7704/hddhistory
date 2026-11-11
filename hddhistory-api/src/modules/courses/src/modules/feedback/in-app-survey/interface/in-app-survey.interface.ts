import { ITranslation } from '@utils/interface/common.interface';

import { InAppSurveyClosedQuestionType } from '../enum/in-app-survey.enum';

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
  configKey: string;
  introQuestion: IInAppSurveyQuestion;
  branches: IInAppSurveyBranch[];
}

export interface IInAppSurveyResponseClosedQuestion
  extends IInAppSurveyQuestion {
  type: InAppSurveyClosedQuestionType;
}

export interface IInAppSurveyResponseBranch {
  emoji: IInAppSurveyEmoji;
  closedQuestion: IInAppSurveyResponseClosedQuestion;
  openQuestion: IInAppSurveyQuestion;
}

export interface IInAppSurveyResponse {
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
  submittedAt?: Date;
  completedAt?: Date;
}

export interface IInAppSurveyUserSnapshot {
  name?: string;
  email?: string;
  avatar?: string;
}

export interface IInAppSurveySession {
  userId: string;
  userSnapshot?: IInAppSurveyUserSnapshot | null;
  configKey: string;
  startedAt: Date;
  completedAt?: Date;
  responseId?: string;
  branchId?: string;
  ratingScore?: number;
}
