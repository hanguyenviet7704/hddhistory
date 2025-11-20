import { KeypointLevel } from "../../../../utils/enum/course.enum";
import { ITranslation } from "../../../../utils/translate";
import { ExerciseType } from "../../../enum/learningItem.enum";
import { ITag } from "../../tag.interface";
import { IDocument } from "../document.interface";
import { IExerciseChoiceOption } from "./single-choice.interface";

export interface IExerciseMultipleChoice {
  id: number;
  type: ExerciseType;
  speechBubble: ITranslation;
  tag: ITag | null;
  document: IDocument[];
  explanation: ITranslation;
  options: IExerciseChoiceOption[];
  level: KeypointLevel[];
  maxScore: number;
  completionTime: number;
  mainQuestion?: number;
  keypointId?: string;
}

export interface ExerciseMultipleChoicePayload {
  id: number;
  type: ExerciseType;
  speechBubble: ITranslation;
  tagId: string;
  document: IDocument[];
  explanation: ITranslation;
  options: IExerciseChoiceOption[];
  level: KeypointLevel[];
  maxScore: number;
  completionTime: number;
  mainQuestion?: number;
  keypointId?: string;
}
