import { KeypointLevel } from "../../../../utils/enum/course.enum";
import { ITranslation } from "../../../../utils/translate";
import {
  ExerciseType,
  FormDragDropType,
} from "../../../enum/learningItem.enum";
import { ITag } from "../../tag.interface";
import { IDocument } from "../document.interface";

export interface IAnswer {
  id: number;
  correctAnswer: ITranslation;
}

export interface IOptions {
  id: number;
  text: ITranslation;
}

export interface IExerciseDragDrop {
  id: number;
  type: ExerciseType;
  form: FormDragDropType;
  tag: ITag | null;
  document: IDocument[];
  explanation: ITranslation;
  targetArea: ITranslation;
  answer: IAnswer[];
  options: IOptions[];
  level: KeypointLevel[];
  maxScore: number;
  mainQuestion?: number;
  keypointId?: string;
}

export interface ExerciseDragDropPayload {
  id: number;
  type: ExerciseType;
  form: FormDragDropType;
  tagId: string;
  document: IDocument[];
  explanation: ITranslation;
  targetArea: ITranslation;
  answer: IAnswer[];
  options: IOptions[];
  level: KeypointLevel[];
  maxScore: number;
  mainQuestion?: number;
  keypointId?: string;
}
