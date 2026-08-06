import { ITranslation } from "../../utils/translate";
import { HabitCheckinMethod, UserHabitState } from "../enum/habit.enum";

/** Mirrors the API's IAdminHabitUser — deliberately narrow. */
export interface IAdminHabitUser {
  id: string;
  email?: string;
  name?: string;
  role?: string;
  status?: string;
}

/** One day's check-in for one adopted habit. */
export interface IUserHabitCheckin {
  date: string; // YYYY-MM-DD
  done: boolean;
  /** Journal free text. Personal diary content — shown in full, on purpose. */
  note?: string;
  method?: HabitCheckinMethod;
  /** 3-level journal mood, 1-based (the API never sends 0). */
  mood?: number;
  /** Correct-answer count of a quiz practice. */
  score?: number;
}

/** A row of GET /user-habits/admin. */
export interface IAdminUserHabitSummary {
  userId: string;
  user: IAdminHabitUser | null;
  habitCount: number;
  activeCount: number;
  totalCheckIns: number;
  bestStreak: number;
  lastCheckInDate?: string | null;
  /** Counted straight off habit_checkins, so these don't drift. */
  checkinRows: number;
  doneCount: number;
  journalCount: number;
  quizCount: number;
}

/** One adopted habit inside the detail view, with its whole log. */
export interface IAdminUserHabitDetailItem {
  id: string;
  habitId: string;
  /** Null when the library entry was deleted — an orphaned habit. */
  title: ITranslation | null;
  state: UserHabitState;
  reminderTime?: string;
  packLength: number;
  startedAt: string;
  currentStreak: number;
  bestStreak: number;
  totalCheckIns: number;
  lastCheckInDate?: string | null;
  sourceKeypointId?: string | null;
  sourceCourseId?: string | null;
  reanchorReason?: ITranslation | null;
  checkins: IUserHabitCheckin[];
}

export interface IAdminUserHabitDetail {
  user: IAdminHabitUser | null;
  habits: IAdminUserHabitDetailItem[];
  totals: {
    habitCount: number;
    activeCount: number;
    checkinRows: number;
    doneCount: number;
    journalCount: number;
    quizCount: number;
  };
}

export interface AdminUserHabitsQuery {
  page?: number;
  take?: number;
  search?: string;
  state?: UserHabitState;
}

export interface AdminUserHabitDetailQuery {
  from?: string;
  to?: string;
}

/** The API's standard list envelope (IResponseListPage). */
export interface AdminUserHabitsResponse {
  items: IAdminUserHabitSummary[];
  itemsPerPage: number;
  totalPages: number;
  currentPage: number;
}
