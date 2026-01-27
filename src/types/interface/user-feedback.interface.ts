import { ITranslation } from "../../utils/translate";
import { IncompleteFeedbackReason } from "../enum/feedback.enum";

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
