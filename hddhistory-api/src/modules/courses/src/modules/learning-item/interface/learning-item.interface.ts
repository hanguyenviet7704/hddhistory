import { ITranslation } from '@utils/interface/common.interface';

import { LearningItemType } from '../enum/learning-item.enum';
import { IExerciseDragDrop } from './excercises/drag-drop.interface';
import { IExerciseMultipleChoice } from './excercises/multiple-choice.interface';
import { IExerciseRecord } from './excercises/record.interface';
import { IExerciseSingleChoiceNoCorrectAnswer } from './excercises/single-choice-no-correct-answer.interface';
import { IExerciseSingleChoice } from './excercises/single-choice.interface';
import { IRoleplay } from './roleplays/roleplay.interface';
import { ITheoryDocument } from './theories/theory.interface';
import { IVideoQuestion } from './videos/video-question.interface';

export interface ILearningItem {
  keypointId: string;
  title: ITranslation;
  description: ITranslation;
  image: string;
  tag: string[];
  type: LearningItemType;
  questions: ExerciseInput[];
  subQuestions: ExerciseInput[];
  videoQuestions?: IVideoQuestion[];
  isSub: boolean;
  documents: ITheoryDocument[];
  roleplay: IRoleplay;
  index: number;
}

export type ExerciseInput =
  | Partial<IExerciseSingleChoice>
  | Partial<IExerciseMultipleChoice>
  | Partial<IExerciseSingleChoiceNoCorrectAnswer>
  | Partial<IExerciseDragDrop>
  | Partial<IExerciseRecord>;
