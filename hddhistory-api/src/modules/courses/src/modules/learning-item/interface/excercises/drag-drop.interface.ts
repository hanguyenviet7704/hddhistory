import { KeypointLevel } from '@utils/enum/course.enum';
import { ITranslation } from '@utils/interface/common.interface';

import { ExerciseType, FormDragDropType } from '../../enum/learning-item.enum';
import { IDocument } from '../document.interface';

export interface IDragDropAnswer {
  id: number;
  correctAnswer: ITranslation;
}

export interface IDragDropOptions {
  id: number;
  text: ITranslation;
}

export interface IExerciseDragDrop {
  id: number;
  exerciseId: string;
  type: ExerciseType;
  form: FormDragDropType;
  tagId: string;
  document: IDocument[];
  explanation: ITranslation;
  targetArea: ITranslation;
  answer: IDragDropAnswer[];
  options: IDragDropOptions[];
  level: KeypointLevel[];
  maxScore: number;
  isDailyWarmUp?: boolean;
  mainQuestion?: number;
  keypointId?: string;
}
