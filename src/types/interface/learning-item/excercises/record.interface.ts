import { KeypointLevel } from "../../../../utils/enum/course.enum";
import { ExerciseType } from "../../../enum/learningItem.enum";
import { ITag } from "../../tag.interface";
import { IDocument } from "../document.interface";

export interface IExerciseRecord {
  id: number;
  type: ExerciseType;
  speechBubble: string;
  tag: ITag | null;
  document: IDocument[];
  explanation: string;
  record: string;
  maxDuration?: number;
  maxCharacter?: number;
  level: KeypointLevel[];
  maxScore: number;
  completionTime: number;
  mainQuestion?: number;
  keypointId?: string;
}

export interface ExerciseRecordPayload {
  id: number;
  type: ExerciseType;
  speechBubble: string;
  tag: string;
  document: IDocument[];
  explanation: string;
  record: string;
  maxDuration?: number;
  maxCharacter?: number;
  level: KeypointLevel[];
  maxScore: number;
  completionTime: number;
  mainQuestion?: number;
  keypointId?: string;
}
