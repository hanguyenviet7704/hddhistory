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

// ---------------------------------------------------------------------------
// Statistics ("Thống kê" tab)
// ---------------------------------------------------------------------------

/** `delta` is null when the window is open-ended — no previous period to compare. */
export interface IHabitStatMetric {
  value: number | null;
  delta?: number | null;
}

export interface IHabitDailyPoint {
  date: string;
  checkins: number;
  done: number;
  users: number;
}

export interface IHabitMethodSlice {
  method: HabitCheckinMethod;
  count: number;
  percent: number;
}

export interface IHabitMoodSlice {
  mood: number;
  count: number;
  percent: number;
}

export interface IHabitTopRow {
  habitId: string;
  /** Null when the library entry was deleted — the row still counts real usage. */
  title: ITranslation | null;
  checkins: number;
  done: number;
  users: number;
  doneRate: number;
}

export interface IHabitStreakBucket {
  from: number;
  isOverflow: boolean;
  count: number;
}

export interface IHabitNoteRow {
  userId: string;
  habitId: string;
  title: ITranslation | null;
  date: string;
  note: string;
  mood?: number;
  method?: HabitCheckinMethod;
  score?: number;
}

export interface IHabitCheckinStatistics {
  range: { startDate: string | null; endDate: string | null };
  metrics: {
    checkins: IHabitStatMetric;
    users: IHabitStatMetric;
    doneRate: IHabitStatMetric;
    habitsTouched: IHabitStatMetric;
    withNote: IHabitStatMetric;
    averageMood: IHabitStatMetric;
    quizCount: IHabitStatMetric;
    averageQuizScore: IHabitStatMetric;
    activeHabits: IHabitStatMetric;
    draftHabits: IHabitStatMetric;
    archivedHabits: IHabitStatMetric;
    adoptedByUsers: IHabitStatMetric;
  };
  daily: IHabitDailyPoint[];
  methodDistribution: IHabitMethodSlice[];
  moodDistribution: IHabitMoodSlice[];
  topHabits: IHabitTopRow[];
  streakBuckets: IHabitStreakBucket[];
  notes: IHabitNoteRow[];
}

export interface IHabitCheckinStatisticsQuery {
  startDate?: string;
  endDate?: string;
}
