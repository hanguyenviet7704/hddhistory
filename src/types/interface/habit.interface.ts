import { ITranslation } from "../../utils/translate";
import { HabitStatus } from "../enum/habit.enum";

export interface IHabit {
  _id: string;
  title: ITranslation;
  skillsetId: string;
  status: HabitStatus;
  defaultReminderTime?: string;
  order: number;
  // Keypoints this habit can be suggested in (many-to-many, PRD v2.0 §9.2). A
  // habit may be suggested by several keypoints; a keypoint may suggest
  // several habits.
  keypointIds?: string[];
  createdAt?: string;
  updatedAt?: string;
}

export interface HabitPayload {
  title: ITranslation;
  skillsetId: string;
  status?: HabitStatus;
  defaultReminderTime?: string;
  order?: number;
  keypointIds?: string[];
}

// GET /habits — the admin list always fetches with isAll=true (no pagination
// envelope, sorted by order asc / createdAt desc on the backend). `status` is
// ignored by the API when isAll is set, so status filtering happens client
// side; `skillsetId` still narrows the server-side query.
export interface HabitListQuery {
  isAll?: boolean;
  skillsetId?: string;
  /** Habits on any keypoint of this course, resolved server side. */
  courseId?: string;
  status?: HabitStatus;
}
