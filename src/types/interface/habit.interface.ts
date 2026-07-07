import { ITranslation } from "../../utils/translate";
import { HabitStatus } from "../enum/habit.enum";

export interface IHabit {
  _id: string;
  title: ITranslation;
  icon: string;
  skillsetId: string;
  status: HabitStatus;
  defaultReminderTime?: string;
  order: number;
  // Lessons this habit can be suggested in (many-to-many, PRD v2.0 §9.2). A
  // habit may be suggested by several lessons; a lesson may suggest several
  // habits.
  lessonIds?: string[];
  createdAt?: string;
  updatedAt?: string;
}

export interface HabitPayload {
  title: ITranslation;
  icon: string;
  skillsetId: string;
  status?: HabitStatus;
  defaultReminderTime?: string;
  order?: number;
  lessonIds?: string[];
}

// GET /habits — the admin list always fetches with isAll=true (no pagination
// envelope, sorted by order asc / createdAt desc on the backend). `status` is
// ignored by the API when isAll is set, so status filtering happens client
// side; `skillsetId` still narrows the server-side query.
export interface HabitListQuery {
  isAll?: boolean;
  skillsetId?: string;
  status?: HabitStatus;
}
