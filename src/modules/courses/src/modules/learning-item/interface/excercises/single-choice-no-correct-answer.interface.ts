import { KeypointLevel } from '@utils/enum/course.enum';
import { ITranslation } from '@utils/interface/common.interface';

import { ExerciseType } from '../../enum/learning-item.enum';
import { IDocument } from '../document.interface';

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
  tagId: string;
  document: IDocument[];
  explanation: ITranslation;
  options: IExerciseSingleChoiceNoCorrectAnswerOption[];
  documentGroups: IExerciseSingleChoiceNoCorrectAnswerDocumentGroup[];
  level: KeypointLevel[];
  maxScore: number;
  isDailyWarmUp?: boolean;
  mainQuestion?: number;
  keypointId?: string;
}
