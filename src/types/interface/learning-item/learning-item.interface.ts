import { ITranslation } from "../../../utils/translate";
import { LearningItemType } from "../../enum/learningItem.enum";
import { BaseQuery } from "../common.interface";
import {
  ExerciseDragDropPayload,
  IExerciseDragDrop,
} from "./excercises/drag-drop.interface";
import {
  ExerciseMultipleChoicePayload,
  IExerciseMultipleChoice,
} from "./excercises/multiple-choice.interface";
import {
  ExerciseRecordPayload,
  IExerciseRecord,
} from "./excercises/record.interface";
import {
  ExerciseSingleChoiceNoCorrectAnswerPayload,
  IExerciseSingleChoiceNoCorrectAnswer,
} from "./excercises/single-choice-no-correct-answer.interface";
import {
  ExerciseSingleChoicePayload,
  IExerciseSingleChoice,
} from "./excercises/single-choice.interface";
import { IRoleplay, IRoleplayPayload } from "./roleplays/roleplay.interface";
import {
  ITheoryDocument,
  TheoryDocumentPayload,
} from "./theories/theory.interface";
import {
  IVideoQuestion,
  VideoQuestionPayload,
} from "./videos/video-question.interface";

export interface ILearningItemBrief {
  _id: string;
  keypointId: string;
  title: ITranslation;
  image: string;
  type: LearningItemType;
  isSub: boolean;
  index: number;
}

interface LearningItemIndex {
  id: string;
  index: number;
}

export interface LearningItemsIndexPayload {
  keypointId: string;
  learningItems: LearningItemIndex[];
}

export interface ILearningItem {
  _id: string;
  keypointId: string;
  title: ITranslation;
  description?: ITranslation;
  image: string;
  tag: string[];
  type: LearningItemType;
  questions: ExerciseInput[];
  subQuestions: ExerciseInput[];
  videoQuestions?: IVideoQuestion[];
  isSub: boolean;
  documents: ITheoryDocument[];
  roleplay?: IRoleplay;
  index: number;
}

export interface LearningItemPayload {
  keypointId: string;
  title: ITranslation;
  description?: ITranslation;
  image: string;
  tag: string[];
  type: LearningItemType;
  questions?: ExerciseInputPayload[];
  subQuestions?: ExerciseInputPayload[];
  videoQuestions?: VideoQuestionPayload[];
  isSub: boolean;
  documents?: TheoryDocumentPayload[];
  roleplay?: IRoleplayPayload;
  index: number;
}

export type ExerciseInput =
  | Partial<IExerciseSingleChoice>
  | Partial<IExerciseSingleChoiceNoCorrectAnswer>
  | Partial<IExerciseMultipleChoice>
  | Partial<IExerciseDragDrop>
  | Partial<IExerciseRecord>;

export type ExerciseInputPayload =
  | Partial<ExerciseSingleChoicePayload>
  | Partial<ExerciseSingleChoiceNoCorrectAnswerPayload>
  | Partial<ExerciseMultipleChoicePayload>
  | Partial<ExerciseDragDropPayload>
  | Partial<ExerciseRecordPayload>;

interface LearningItemIndex {
  id: string;
  index: number;
}

export interface LearningItemsIndexPayload {
  keypointId: string;
  learningItems: LearningItemIndex[];
}

export class LearningItemListQuery extends BaseQuery {
  type?: LearningItemType;
  keypointId?: string;
  constructor(init?: Partial<LearningItemListQuery>) {
    super(init);
    Object.assign(this, init);
  }

  override toQueryParams(): string {
    const params = new URLSearchParams(super.toQueryParams());
    if (this.type) params.set("type", this.type);
    if (this.keypointId) params.set("keypointId", this.keypointId);

    return params.toString();
  }
}
