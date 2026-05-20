import { KeypointLevel } from "../../../../utils/enum/course.enum";
import { ITranslation } from "../../../../utils/translate";
import { ExerciseType } from "../../../enum/learningItem.enum";
import { ITag } from "../../tag.interface";
import { IDocument } from "../document.interface";

export interface IScoringCriteria {
  maxScore: number;
  criteria: ITranslation;
}

export interface IExerciseRecord {
  id: number;
  type: ExerciseType;
  tag: ITag | null;
  document: IDocument[];
  explanation: ITranslation;
  record: string;
  maxDuration?: number;
  maxCharacter?: number;
  scoringCriteria: IScoringCriteria[];
  level: KeypointLevel[];
  maxScore: number;
  isDailyWarmUp?: boolean;
  mainQuestion?: number;
  keypointId?: string;
}

export interface ExerciseRecordPayload {
  id: number;
  type: ExerciseType;
  tagId: string;
  document: IDocument[];
  explanation: string;
  record: string;
  maxDuration?: number;
  maxCharacter?: number;
  scoringCriteria: IScoringCriteria[];
  level: KeypointLevel[];
  maxScore: number;
  isDailyWarmUp?: boolean;
  mainQuestion?: number;
  keypointId?: string;
}
