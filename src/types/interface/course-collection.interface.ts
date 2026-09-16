import { ITranslation } from "../../utils/translate";

/**
 * Hard cap on a collection's courses, mirrored from the API's own DTO
 * validation. The Explore strip shows the whole collection, so a ninth course
 * would simply never be seen — and the save would be rejected anyway.
 */
export const COLLECTION_MAX_COURSES = 8;

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
