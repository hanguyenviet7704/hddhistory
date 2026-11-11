/**
 * Bài học người dùng tự tạo từ PDF / YouTube ("Bài tôi tạo").
 *
 * KHÔNG phải bài trong catalogue: API cất chúng ở collection riêng
 * (`user_lessons`), chuỗi là chuỗi thường một ngôn ngữ chứ không phải
 * MultiLang, và tiến độ đọc lưu ngay trên bài chứ không qua `user_progress`.
 * Hình dạng lấy từ `user-lesson.service.ts` (`UserLessonSummary`, `findOne`).
 */
import 'server-only';

import { request, type PageBreak } from './api';

export interface LessonBlock {
  type?: 'heading' | 'paragraph';
  text?: string;
}

/** Một THẺ trong trình đọc. Tên "section" có từ hồi bài còn là danh sách phẳng. */
export interface LessonSection {
  title?: string;
  blocks?: LessonBlock[];
}

export interface LessonKeypoint {
  title?: string;
  sections?: LessonSection[];
  coverUrl?: string;
  /** Mặt sau của thẻ tổng kết cuối keypoint. Bài cũ không có. */
  takeaway?: string;
}

export interface KeypointAudio {
  keypointIndex: number;
  url: string;
  durationMs?: number;
}

/** Thẻ trong danh sách — KHÔNG có thân bài. */
export interface UserLessonSummary {
  id: string;
  title?: string;
  description?: string;
  outputLocale?: string;
  sourceType?: string;
  sourceLabel?: string;
  wordCount?: number;
  estimatedMinutes?: number;
  stopAtKeypointIndex?: number;
  stopAtSectionIndex?: number;
  coverUrl?: string;
  completedAt?: string | null;
  additionalContentRequestedAt?: string | null;
  createdAt?: string;
  audioStatus?: 'none' | 'processing' | 'ready' | 'failed';
  /** `partial` khi các keypoint sau vẫn đang được viết sau lưng người đọc. */
  contentStatus?: 'partial' | 'complete';
}

export interface UserLessonDetail extends UserLessonSummary {
  keypoints?: LessonKeypoint[];
  /** Dàn ý đã chốt — cho phép vẽ cả các keypoint chưa được viết. */
  plannedKeypointTitles?: string[];
  plannedKeypointCoverUrls?: string[];
  audio?: { voice?: string; keypoints?: KeypointAudio[] } | null;
  /** Server còn nợ lời đọc cho bài này (đang lồng tiếng dần). */
  audioPending?: boolean;
}

export function getUserLessons(
  page = 1,
  take = 20,
): Promise<PageBreak<UserLessonSummary>> {
  // Tiến độ đọc đổi sau mỗi thẻ — cache 30 giây là thấy % cũ khi quay lại.
  return request<PageBreak<UserLessonSummary>>(
    `/api/v1/user-lessons?page=${page}&take=${take}`,
    { revalidate: 0 },
  );
}

export function getUserLesson(id: string): Promise<UserLessonDetail> {
  return request<UserLessonDetail>(
    `/api/v1/user-lessons/${encodeURIComponent(id)}`,
    { revalidate: 0 },
  );
}

/**
 * Phần trăm đã đọc, đúng công thức của app (`UserLessonEntity.readPercent`):
 * tính theo keypoint đang dừng chứ không theo thẻ, và 100 chỉ khi server đã
 * đóng dấu `completedAt`.
 */
export function readPercent(
  lesson: UserLessonSummary,
  keypointCount?: number,
): number {
  if (lesson.completedAt) return 100;
  const stop = lesson.stopAtKeypointIndex ?? 0;
  // Thẻ trong danh sách không có thân bài; app lấy `stop + 1` làm mẫu số để
  // thẻ không kẹt 0% mãi.
  const total = keypointCount && keypointCount > 0 ? keypointCount : stop + 1;
  if (stop <= 0) return 0;
  return Math.min(100, Math.max(0, Math.round((stop / total) * 100)));
}
