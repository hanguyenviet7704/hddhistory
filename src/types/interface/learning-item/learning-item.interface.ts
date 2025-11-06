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
  ExerciseSingleChoicePayload,
  IExerciseSingleChoice,
} from "./excercises/single-choice.interface";
import { ISection } from "./roleplays/section.interface";
import {
  ITheoryDocument,
  TheoryDocumentPayload,
} from "./theories/theory.interface";

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
  isSub: boolean;
  documents: ITheoryDocument[];
  sections?: ISection[];
  index: number;
}

export interface LearningItemPayload {
  keypointId: string;
  title: string;
  description?: string;
  image: string;
  tag: string[];
  type: LearningItemType;
  questions?: ExerciseInputPayload[];
  subQuestions?: ExerciseInputPayload[];
  isSub: boolean;
  documents?: TheoryDocumentPayload[];
  sections?: ISection[];
  index: number;
}

export type ExerciseInput =
  | Partial<IExerciseSingleChoice>
  | Partial<IExerciseMultipleChoice>
  | Partial<IExerciseDragDrop>
  | Partial<IExerciseRecord>;

export type ExerciseInputPayload =
  | Partial<ExerciseSingleChoicePayload>
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
