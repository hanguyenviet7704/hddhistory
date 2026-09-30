import { KeypointLevel } from '@utils/enum/course.enum';
import { ITranslation } from '@utils/interface/common.interface';

import { ExerciseType } from '../../enum/learning-item.enum';
import { IDocument } from '../document.interface';

interface IExerciseChoiceOption {
  value: ITranslation;
  isCorrect: boolean;
}

export interface IExerciseSingleChoice {
  id: number;
  exerciseId: string;
  type: ExerciseType;
  tagId: string;
  document: IDocument[];
  explanation: ITranslation;
  options: IExerciseChoiceOption[];
  level: KeypointLevel[];
  maxScore: number;
  isDailyWarmUp?: boolean;
  mainQuestion?: number;
  keypointId?: string;
}
