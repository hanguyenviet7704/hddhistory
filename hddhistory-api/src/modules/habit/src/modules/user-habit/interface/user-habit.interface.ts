import { Types } from 'mongoose';

import { ITranslation } from '@utils/interface/common.interface';

import {
  HabitCheckinMethod,
  HabitPackLength,
  UserHabitState,
} from '../enum/user-habit.enum';

export interface IUserHabit {
  userId: string;
  habitId: Types.ObjectId | string;
  state: UserHabitState;
  reminderTime?: string;
  packLength: HabitPackLength;
  startedAt: Date;
  currentStreak: number;
  bestStreak: number;
  totalCheckIns: number;
  lastCheckInDate?: Date | null;
  sourceKeypointId?: Types.ObjectId | string | null;
  sourceCourseId?: Types.ObjectId | string | null;
  reanchorReasonId?: Types.ObjectId | string | null;
  reanchorReason?: ITranslation | null;
}

export interface IHabitCheckin {
  userHabitId: Types.ObjectId | string;
  date: Date;
  done: boolean;
  note?: string;
  method?: HabitCheckinMethod;
  mood?: number;
  score?: number;
}

// Response item for GET /user-habits/:id/checkins — powers the Habit detail
// heatmap (done flag per date) and diary list (mood + note per date).
export interface IUserHabitCheckinLogItem {
  date: string;
  done: boolean;
  note?: string;
  method?: HabitCheckinMethod;
  mood?: number;
  score?: number;
}

// --- Admin surface (@Roles(ADMIN) only) ---

// The user identity shown next to their habit activity. Deliberately narrow:
// this is a support/insight view, not a user-management one.
export interface IAdminHabitUser {
  id: string;
  email?: string;
  name?: string;
  role?: string;
  status?: string;
}

// One row of GET /user-habits/admin — a user and how much they engage.
export interface IAdminUserHabitSummary {
  userId: string;
  user: IAdminHabitUser | null;
  habitCount: number;
  activeCount: number;
  totalCheckIns: number;
  bestStreak: number;
  lastCheckInDate?: Date | null;
  // Straight off habit_checkins, so these stay true even if the denormalised
  // counters on user_habits ever drift.
  checkinRows: number;
  doneCount: number;
  journalCount: number;
  quizCount: number;
}

// One habit inside GET /user-habits/admin/users/:userId, with its full log.
export interface IAdminUserHabitDetailItem {
  id: string;
  habitId: string;
  title: Record<string, string> | null;
  state: UserHabitState;
  reminderTime?: string;
  packLength: HabitPackLength;
  startedAt: Date;
  currentStreak: number;
  bestStreak: number;
  totalCheckIns: number;
  lastCheckInDate?: Date | null;
  sourceKeypointId?: string | null;
  sourceCourseId?: string | null;
  reanchorReason?: ITranslation | null;
  checkins: IUserHabitCheckinLogItem[];
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

// Aggregate powering the post-lesson summary ring (design.md 5.4) and the
// Habit tab header. checkInRate = share of the user's ACTIVE habits already
// checked in as done "today" — [ASSUMPTION] the design only shows a single
// percentage with no stated formula, so "today's completion rate" is the
// simplest reading of a ring shown right after finishing a lesson.
export interface IUserHabitBestHabit {
  title: Record<string, string>;
  loop: number;
}

export interface IUserHabitSummary {
  checkInRate: number;
  activeCount: number;
  bestStreak: number;
  totalCheckIns: number;
  // Weekly recap (Figma): total lessons the user has passed + their best habit.
  totalLessons: number;
  bestHabit: IUserHabitBestHabit | null;
}
