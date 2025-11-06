import { KeypointLevel } from "../../../../utils/enum/course.enum";
import { ExerciseType } from "../../../enum/learningItem.enum";
import { ITag } from "../../tag.interface";
import { IDocument } from "../document.interface";

export interface IExerciseChoiceOption {
  value: string;
  isCorrect: boolean;
}

export interface IExerciseSingleChoice {
  id: number;
  type: ExerciseType;
  speechBubble: string;
  tag: ITag | null;
  document: IDocument[];
  explanation: string;
  options: IExerciseChoiceOption[];
  level: KeypointLevel[];
  maxScore: number;
  completionTime: number;
  mainQuestion?: number;
  keypointId?: string;
}

export interface ExerciseSingleChoicePayload {
  id: number;
  type: ExerciseType;
  speechBubble: string;
  tag: string;
  document: IDocument[];
  explanation: string;
  options: IExerciseChoiceOption[];
  level: KeypointLevel[];
  maxScore: number;
  completionTime: number;
  mainQuestion?: number;
  keypointId?: string;
}
