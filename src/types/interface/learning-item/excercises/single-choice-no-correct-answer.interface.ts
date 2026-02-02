import { KeypointLevel } from "../../../../utils/enum/course.enum";
import { ITranslation } from "../../../../utils/translate";
import { ExerciseType } from "../../../enum/learningItem.enum";
import { ITag } from "../../tag.interface";
import { IDocument } from "../document.interface";

export interface IExerciseSingleChoiceNoCorrectAnswerOption {
  value: ITranslation;
  documentGroupId: string;
}

export interface IExerciseSingleChoiceNoCorrectAnswerDocumentGroup {
  id: string;
  documents: IDocument[];
}

export interface IExerciseSingleChoiceNoCorrectAnswer {
  id: number;
  exerciseId: string;
  type: ExerciseType;
  tag: ITag | null;
  document: IDocument[];
  explanation: ITranslation;
  options: IExerciseSingleChoiceNoCorrectAnswerOption[];
  documentGroups: IExerciseSingleChoiceNoCorrectAnswerDocumentGroup[];
  level: KeypointLevel[];
  maxScore: number;
  mainQuestion?: number;
  keypointId?: string;
}

export interface ExerciseSingleChoiceNoCorrectAnswerPayload {
  id: number;
  exerciseId: string;
  type: ExerciseType;
  tagId: string; // | null;
  document: IDocument[];
  explanation: ITranslation;
  options: IExerciseSingleChoiceNoCorrectAnswerOption[];
  documentGroups: IExerciseSingleChoiceNoCorrectAnswerDocumentGroup[];
  level: KeypointLevel[];
  maxScore: number;
  mainQuestion?: number;
  keypointId?: string;
}
