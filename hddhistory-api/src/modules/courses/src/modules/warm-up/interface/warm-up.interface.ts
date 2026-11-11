import { ITranslation } from '@utils/interface/common.interface';

import { ExerciseInput } from '../../learning-item/interface/learning-item.interface';

export interface IWarmUpPreviousLesson {
  id: string;
  title: ITranslation;
  questions: ExerciseInput[];
}

export interface IWarmUpForCourseResponse {
  isDue: boolean;
  previousLesson: IWarmUpPreviousLesson | null;
}
