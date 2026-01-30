import { KeypointLevel } from "../../../../utils/enum/course.enum";
import { ITranslation } from "../../../../utils/translate";
import { ExerciseType } from "../../../enum/learningItem.enum";
import { ITag } from "../../tag.interface";
import { IDocument } from "../document.interface";

export interface IExerciseSurveyChoiceOption {
  value: ITranslation;
  documentGroupId: string;
}

export interface IExerciseSurveyDocumentGroup {
  id: string;
  documents: IDocument[];
}

export interface IExerciseSingleChoiceSurvey {
  id: number;
  exerciseId: string;
  type: ExerciseType;
  tag: ITag | null;
  document: IDocument[];
  explanation: ITranslation;
  options: IExerciseSurveyChoiceOption[];
  documentGroups: IExerciseSurveyDocumentGroup[];
  level: KeypointLevel[];
  maxScore: number;
  mainQuestion?: number;
  keypointId?: string;
}

export interface ExerciseSingleChoiceSurveyPayload {
  id: number;
  exerciseId: string;
  type: ExerciseType;
  tagId: string;
  document: IDocument[];
  explanation: ITranslation;
  options: IExerciseSurveyChoiceOption[];
  documentGroups: IExerciseSurveyDocumentGroup[];
  level: KeypointLevel[];
  maxScore: number;
  mainQuestion?: number;
  keypointId?: string;
}
