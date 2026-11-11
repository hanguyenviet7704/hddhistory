/**
 * HDDhistory Coach — cuộc trò chuyện có kịch bản phía server.
 *
 * Hình dạng lấy từ `coach-response.interface.ts` của API và dò lại trên API
 * local. Hợp đồng i18n quan trọng nhất: một lượt mang HOẶC `reply` (câu model
 * viết sẵn bằng tiếng của người đọc, hiện nguyên văn) HOẶC `promptKey` (câu cố
 * định, client tự dịch từ bảng chữ của mình) — không bao giờ cả hai.
 */
import 'server-only';

import { request } from './api';

export type CoachPersona = 'friend' | 'direct' | 'guide';

export type CoachUiKind =
  | 'chips'
  | 'text'
  | 'text_skippable'
  | 'hub'
  | 'depth'
  | 'two_cols'
  | 'next_action'
  | 'closing'
  | 'shrink'
  | 'plan'
  | 'schedule'
  | 'course_card'
  | 'scene_score'
  | 'rating'
  | 'next_session'
  | 'end'
  | 'safety';

/** Một lựa chọn. `label` chỉ có với lựa chọn dựng từ DỮ LIỆU (tên habit…). */
export interface CoachChoice {
  value: string;
  label?: string | null;
  /** Câu trả lời app đã biết — chip được thắp sẵn, người đọc xác nhận hoặc đổi. */
  selected?: boolean;
}

export interface CoachSceneOption {
  key: string;
  label: string;
  text: string;
}

export interface CoachScene {
  habit?: string | null;
  setup: string;
  question?: string | null;
  options?: CoachSceneOption[];
  optionsLead?: string | null;
}

export interface CoachHotline {
  locale?: string;
  country?: string | null;
  label: string;
  number: string;
}

export interface CoachCourseCard {
  courseId: string;
  title: string;
  image?: string | null;
  habitTitle?: string | null;
  author?: string | null;
  viewCount?: number | null;
  reasonKey?: string | null;
  reasonArgs?: Record<string, string> | null;
}

export interface CoachScore {
  criteria: { key: string; label: string; score: number; note?: string | null }[];
  overall: number;
  strength?: string | null;
  improve?: string | null;
  tip?: string | null;
  betterPhrasing?: string | null;
  level: number;
  retryAvailable?: boolean;
  skill?: {
    score: number | null;
    scenes: number;
    level: number;
    trend: number | null;
  } | null;
}

export interface CoachUi {
  kind: CoachUiKind;
  choices?: CoachChoice[];
  columns?: { left: string[]; right: string[] };
  rejectAvailable?: boolean;
  habit?: { id: string; title: string } | null;
  scope?: { kind: 'keypoint' | 'course'; title: string } | null;
  situation?: string | null;
  scene?: CoachScene | null;
  samples?: string[];
  hotlines?: CoachHotline[];
  keypoints?: {
    id: string;
    title: string;
    courseId?: string | null;
    courseTitle?: string | null;
  }[];
  escapeAvailable?: boolean;
  quizRemaining?: number;
  action?: string | null;
  onboard?: { step: number; total: number; skippable: boolean } | null;
  course?: CoachCourseCard | null;
  allowNewSession?: boolean;
  suggested?: { context: string; action: string } | null;
  score?: CoachScore | null;
}

export interface CoachReplayItem {
  at: string;
  step?: string | null;
  userLine?: string | null;
  reply?: string | null;
  speaker?: string | null;
  noteKey?: string | null;
  promptKey?: string | null;
  promptArgs?: Record<string, string> | null;
  situation?: string | null;
  scene?: CoachScene | null;
  divider?: { at: string; entry: string } | null;
}

export interface CoachTurn {
  sessionId: string;
  step: string;
  reply: string | null;
  promptKey: string | null;
  promptArgs?: Record<string, string> | null;
  noteKey?: string | null;
  speaker?: string | null;
  persona?: CoachPersona | null;
  ui: CoachUi;
  courseInvite?: { courseId: string; title: string } | null;
  replay?: CoachReplayItem[];
  resumed?: boolean;
  ended: boolean;
  exitPlea?: boolean;
  exitFeedback?: boolean;
  sessionKind?: 'story' | 'scene' | 'recap' | 'onboard' | 'hub';
}

/** Cửa mở ra mà các chốt bảo "im" — kết quả bình thường, không phải lỗi. */
export interface CoachSilent {
  silent: true;
  reasonKey: string;
}

export interface CoachBubble {
  visible: boolean;
  dot: boolean;
  /** Lời hẹn của chính người đọc, trích lại. */
  teaser: string | null;
  /** Hoặc một câu cố định, dạng khoá. */
  teaserKey?: string | null;
}

/** Múi giờ Việt Nam — máy chủ Next không biết múi giờ của trình duyệt. */
export const VN_TZ_OFFSET_MINUTES = 420;

export function getCoachBubble(): Promise<CoachBubble> {
  return request<CoachBubble>(
    `/api/v1/coach/bubble?entry=home&tzOffsetMinutes=${VN_TZ_OFFSET_MINUTES}`,
    // Chấm đỏ đổi theo lời hẹn đang chờ — cũ 30 giây là nói sai.
    { revalidate: 0 },
  );
}
