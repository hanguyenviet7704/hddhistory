import { ITranslation } from "../../utils/translate";
import { HabitCheckinMethod } from "../enum/habit.enum";

export enum HabitPracticeStatus {
  DRAFT = "draft",
  PUBLISHED = "published",
}

/** Learning item types that can serve as a practice. Theory cannot be completed. */
export enum PracticeLearningItemType {
  EXERCISE = "exercise",
  VIDEO = "video",
  ROLEPLAY = "roleplay",
}

/** The learning_item a practice points at, as returned hydrated by the API. */
export interface IPracticeLearningItem {
  _id: string;
  title?: ITranslation;
  description?: ITranslation;
  type: string;
  /** Absent on habit-owned content — which is what keeps it out of daily warm-up. */
  keypointId?: string;
  questions?: unknown[];
}

export interface IHabitPractice {
  _id: string;
  habitId: string;
  learningItemId: string;
  order: number;
  status: HabitPracticeStatus;
  /** Derived server-side from the learning item's `type`, not stored. */
  method?: HabitCheckinMethod;
  learningItem?: IPracticeLearningItem;
  createdAt?: string;
  updatedAt?: string;
}

export interface HabitPracticePayload {
  habitId: string;
  learningItemId: string;
  order?: number;
  status?: HabitPracticeStatus;
}

export interface HabitPracticeUpdatePayload {
  order?: number;
  status?: HabitPracticeStatus;
}
