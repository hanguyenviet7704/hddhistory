/**
 * Tiến độ học: chuỗi ngày, thành tích, nhật ký, tuần san, thẻ đã lưu.
 *
 * Hình dạng dữ liệu ở đây được dò TRỰC TIẾP trên API local đang chạy, không
 * phải suy từ tên endpoint — chính cách đó đã bắt được lỗi `/community/posts`
 * vốn không tồn tại (đường thật là `/community/feed`).
 */
import 'server-only';

import { request } from './api';
import type { MultiLang } from './content';

export interface Streak {
  weekStartDate: string;
  /** Bảy ô thứ Hai → Chủ nhật của tuần hiện tại. */
  weekStudy: boolean[];
  studyTime: number;
  currentStreak: number;
  bestStreak: number;
}

export interface Achievement {
  skillsetId?: string;
  title?: MultiLang;
  total?: number;
  completed?: number;
  percent?: number;
}

export interface StudyJournalDay {
  date: string;
  keypoints?: number;
  lessons?: number;
  minutes?: number;
}

export interface StudyJournal {
  month: string;
  days: StudyJournalDay[];
  summary: { activeDays: number; keypoints: number };
  firstActiveDate: string | null;
}

/** API dùng dạng phân trang riêng ở nhóm này: items + currentPage + totalPages. */
export interface Paged<T> {
  items: T[];
  currentPage: number;
  totalPages: number;
  itemsPerPage: number;
}

export interface SavedCard {
  _id?: string;
  keypointId?: string;
  title?: MultiLang;
  content?: MultiLang;
}

export interface UserLesson {
  _id?: string;
  title?: string;
  status?: string;
  createdAt?: string;
}

export interface WeekRecap {
  _id?: string;
  weekStartDate?: string;
  weekEndDate?: string;
  stats?: { lessons?: number; minutes?: number; habitsKept?: number };
}

export const getStreak = () =>
  request<Streak>('/api/v1/courses-user-progress/streak', { revalidate: 0 });

export const getAchievements = () =>
  request<Achievement[]>('/api/v1/courses-user-progress/achievements');

export const getStudyJournal = (month?: string) =>
  request<StudyJournal>(
    `/api/v1/courses-user-progress/study-journal${month ? `?month=${month}` : ''}`,
  );

export const getSavedCards = () =>
  request<Paged<SavedCard>>('/api/v1/saved-cards?page=1&take=30');

export const getUserLessons = () =>
  request<Paged<UserLesson>>('/api/v1/user-lessons?page=1&take=30');

export const getWeekRecaps = () =>
  request<Paged<WeekRecap>>('/api/v1/courses-user-progress/week-recap?page=1&take=20');

/** Bảng tin cộng đồng. Đường thật là `/community/feed`, KHÔNG phải `/community/posts`. */
export interface CommunityFeed {
  weekly: { title?: string; note?: string } | null;
  pinned: CommunityPost[];
  items: CommunityPost[];
  currentPage: number;
  totalPages: number;
}

export interface CommunityPost {
  id: string;
  author?: { name?: string };
  topic?: { name?: string } | null;
  subject?: string;
  body?: string;
  likeCount?: number;
  commentCount?: number;
  createdAt?: string;
}

export const getCommunityFeed = () =>
  request<CommunityFeed>('/api/v1/community/feed?page=1&take=20');

export const getCommunityPost = (id: string) =>
  request<CommunityPost>(`/api/v1/community/posts/${encodeURIComponent(id)}`);
