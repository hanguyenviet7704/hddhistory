import { ITranslation } from "../../utils/translate";

export enum CourseCollectionStatus {
  DRAFT = "draft",
  PUBLISHED = "published",
}

/**
 * Which of the Explore tab's two curated regions the collection belongs to.
 * `top` is the single strip above the weekly-popular card; `bottom` is the
 * stack below the topic chips.
 */
export enum CourseCollectionSlot {
  TOP = "top",
  BOTTOM = "bottom",
}

export interface ICourseCollection {
  _id: string;
  title: ITranslation;
  description?: ITranslation;
  status: CourseCollectionStatus;
  slot: CourseCollectionSlot;
  /** Order inside the slot. Maintained by drag and drop, not typed by hand. */
  index: number;
  /** EMPTY MEANS EVERYONE. Matching ANY listed segment is enough. */
  segmentIds: string[];
  /** Courses in the order the editor arranged them. */
  courseIds: string[];
}

export type CourseCollectionPayload = Partial<
  Omit<ICourseCollection, "_id">
>;
