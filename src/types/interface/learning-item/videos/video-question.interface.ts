import {
  ExerciseInput,
  ExerciseInputPayload,
} from "../learning-item.interface";

export interface IVideoQuestion {
  atSecond: number;
  exercise: ExerciseInput;
}

export interface VideoQuestionPayload {
  atSecond: number;
  exercise: ExerciseInputPayload;
}
