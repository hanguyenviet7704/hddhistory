import { ITranslation } from "../../utils/translate";
import { HabitStatus } from "../enum/habit.enum";

export interface IHabit {
  _id: string;
  title: ITranslation;
  categoryId: string;
  status: HabitStatus;
  /**
   * The habit's own picture, an absolute CDN url. Empty means the app keeps
   * showing the category's logo, which is what every habit did before.
   */
  image?: string;
  /** What the habit is and when it applies — grounds the Coach's scenes. */
  description?: ITranslation;
  /** Moments the habit comes up, one per line per locale. */
  contexts?: ITranslation;
  /** The skill's rubric — one `key | label` criterion per line per locale (4-5). */
  rubric?: ITranslation;
  /** The skill's difficulty ladder — one `<level> | <shape>` rung per line (5). */
  ladder?: ITranslation;
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
  categoryId: string;
  status?: HabitStatus;
  image?: string;
  description?: ITranslation;
  contexts?: ITranslation;
  rubric?: ITranslation;
  ladder?: ITranslation;
  defaultReminderTime?: string;
  order?: number;
  keypointIds?: string[];
}

// GET /habits — the admin list always fetches with isAll=true (no pagination
// envelope, sorted by order asc / createdAt desc on the backend). `status` is
// ignored by the API when isAll is set, so status filtering happens client
// side; `categoryId` still narrows the server-side query.
export interface HabitListQuery {
  isAll?: boolean;
  categoryId?: string;
  /** Habits on any keypoint of this course, resolved server side. */
  courseId?: string;
  status?: HabitStatus;
}
