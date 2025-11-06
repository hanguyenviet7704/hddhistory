import { KeypointLevel } from "../../../../utils/enum/course.enum";
import {
  ExerciseType,
  FormDragDropType,
} from "../../../enum/learningItem.enum";
import { ITag } from "../../tag.interface";
import { IDocument } from "../document.interface";

export interface IAnswer {
  id: number;
  correctAnswer: string;
}

export interface IOptions {
  id: number;
  text: string;
}

export interface IExerciseDragDrop {
  id: number;
  type: ExerciseType;
  form: FormDragDropType;
  speechBubble: string;
  tag: ITag | null;
  document: IDocument[];
  explanation: string;
  targetArea: string;
  answer: IAnswer[];
  options: IOptions[];
  level: KeypointLevel[];
  maxScore: number;
  completionTime: number;
  mainQuestion?: number;
  keypointId?: string;
}

export interface ExerciseDragDropPayload {
  id: number;
  type: ExerciseType;
  form: FormDragDropType;
  speechBubble: string;
  tag: string;
  document: IDocument[];
  explanation: string;
  targetArea: string;
  answer: IAnswer[];
  options: IOptions[];
  level: KeypointLevel[];
  maxScore: number;
  completionTime: number;
  mainQuestion?: number;
  keypointId?: string;
}
