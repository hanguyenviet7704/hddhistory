/**
 * Tiến độ học: chuỗi ngày, thành tích, nhật ký, hành trình tuần.
 *
 * Hình dạng dữ liệu ở đây được dò TRỰC TIẾP trên API local đang chạy, không
 * phải suy từ tên endpoint — chính cách đó đã bắt được lỗi `/community/posts`
 * vốn không tồn tại (đường thật là `/community/feed`). Nhóm hành trình tuần và
 * nhật ký đối chiếu thêm với `week-recap.service.ts` / `study-journal.service.ts`
 * của API vì tài khoản thử chưa có dữ liệu nào.
 */
import 'server-only';

import { request } from './api';
import type { MultiLang } from './content';

/**
 * Lệch múi giờ của người học, phút về phía đông UTC (+420 = Hà Nội).
 *
 * API cắt "ngày học" và "tuần" theo con số này; thiếu thì nó dùng UTC và một
 * buổi học lúc 6 giờ sáng bị tính vào hôm trước. App gửi múi giờ của máy; máy
 * chủ web không biết múi giờ trình duyệt, và web chỉ có tiếng Việt, nên cố định
 * giờ Việt Nam.
 */
export const TZ_OFFSET = 420;

/** Ngày hôm nay theo giờ Việt Nam, dạng `YYYY-MM-DD`. */
export function localToday(): string {
  return new Date(Date.now() + TZ_OFFSET * 60_000).toISOString().slice(0, 10);
}

export interface Streak {
  weekStartDate: string;
  /** Bảy ô thứ Hai → Chủ nhật của tuần hiện tại. */
  weekStudy: boolean[];
  /** Giây đã học trong tuần. */
  studyTime: number;
  currentStreak: number;
  bestStreak: number;
}

/** Cấu hình admin: học bao lâu thì được "điểm danh" hôm nay. */
export interface StreakConfig {
  triggerAfterSeconds?: number;
  popupEnabled?: boolean;
  autoHideSeconds?: number;
}

export interface AchievementCourse {
  courseId?: string;
  courseTitle?: MultiLang;
  titleBadge?: MultiLang;
  lightBadge?: string;
  level?: string;
  totalKeypoints?: number;
  completedKeypoints?: number;
  isCompleted?: boolean;
}

/** Một chủ đề (category) và các khoá trong đó — huy hiệu là theo khoá. */
export interface Achievement {
  categoryId?: string;
  categoryTitle?: MultiLang;
  courses?: AchievementCourse[];
  totalKeypoints?: number;
  completedKeypoints?: number;
}

/** API chỉ trả những ngày CÓ học; ô trống do client tự vẽ. */
export interface StudyJournalDay {
  date: string;
  keypoints: number;
  /** 0 = không học, 1..4 = bốn sắc độ của chú giải "Ít → Nhiều". */
  level: number;
}

export interface StudyJournal {
  month: string;
  tzOffset?: number;
  days: StudyJournalDay[];
  summary: { activeDays: number; keypoints: number };
  firstActiveDate: string | null;
}

/** Chi tiết một ngày: gộp theo KHOÁ chứ không theo từng keypoint. */
export interface StudyJournalDayDetail {
  date: string;
  summary: { lessons: number; minutes: number; habits: number };
  courses: {
    courseId: string;
    title: string;
    image?: string;
    lessons: number;
    minutes: number;
  }[];
  habits: {
    userHabitId: string;
    habitId: string;
    title: string;
    image?: string;
    method?: string | null;
    note?: string | null;
  }[];
}

/** API dùng dạng phân trang riêng ở nhóm này: items + currentPage + totalPages. */
export interface Paged<T> {
  items: T[];
  currentPage: number;
  totalPages: number;
  itemsPerPage: number;
}

/** Một ô trong "Sổ hành trình" — chỉ có số tuần và khoảng ngày. */
export interface WeekRecapSummary {
  id: string;
  weekNumber: number;
  weekStart: string;
  weekEnd: string;
}

/**
 * Tấm "Hành trình tuần qua". Tiêu đề khoá/bài/thói quen đã được API dịch sẵn
 * theo header `lang`, nên là chuỗi thường chứ không phải MultiLang.
 */
export interface WeekRecapDetail extends WeekRecapSummary {
  stats: {
    activeDays: number;
    streakDays: number;
    habitsKept: number;
    keypoints: number;
    minutes: number;
  };
  days: { date: string; active: boolean; mood: number | null }[];
  lessons: {
    courseId: string;
    courseTitle: string;
    image?: string;
    lessonId: string;
    lessonTitle: string;
  }[];
  habits: { habitId: string; title: string; doneCount: number }[];
  favouriteCourse: { courseId: string; title: string; image?: string } | null;
  coach: {
    evidence?: string[];
    practised?: { done: number; missed: number; noOccasion: number; answers: number };
    change?: { before: string; after: string; weeksApart: number } | null;
    ownWords?: string[];
  } | null;
  viewedAt: string | null;
  dismissedAt: string | null;
}

export interface CurrentWeekRecap {
  /** Null khi tuần trước không có hoạt động — không phải lỗi. */
  recap: WeekRecapDetail | null;
  archiveCount: number;
}

export const getStreak = () =>
  request<Streak>('/api/v1/courses-user-progress/streak', { revalidate: 0 });

export const getStreakConfig = () =>
  request<StreakConfig>('/api/v1/streak-config', { revalidate: 300 });

export const getAchievements = () =>
  request<Achievement[]>('/api/v1/courses-user-progress/achievements', {
    revalidate: 0,
  });

export const getStudyJournal = (month?: string) =>
  request<StudyJournal>(
    `/api/v1/courses-user-progress/study-journal?tzOffset=${TZ_OFFSET}${month ? `&month=${month}` : ''}`,
    { revalidate: 0 },
  );

export const getStudyJournalDay = (date: string) =>
  request<StudyJournalDayDetail>(
    `/api/v1/courses-user-progress/study-journal/day?tzOffset=${TZ_OFFSET}&date=${date}`,
    { revalidate: 0 },
  );

/**
 * Tuần đã khép lại gần nhất. Lần gọi đầu sau thứ Hai chính là lúc API cắt và
 * lưu tấm của tuần đó, nên không cache: cache 30 giây là có thể hiện "chưa có"
 * cho một tuần vừa được tạo.
 */
export const getCurrentWeekRecap = () =>
  request<CurrentWeekRecap>(
    `/api/v1/courses-user-progress/week-recap/current?tzOffset=${TZ_OFFSET}`,
    { revalidate: 0 },
  );

export const getWeekRecap = (id: string) =>
  request<WeekRecapDetail>(
    `/api/v1/courses-user-progress/week-recap/${encodeURIComponent(id)}`,
    { revalidate: 0 },
  );

export const getWeekRecapArchive = (page = 1) =>
  request<Paged<WeekRecapSummary>>(
    `/api/v1/courses-user-progress/week-recap?page=${page}&take=20`,
    { revalidate: 0 },
  );
