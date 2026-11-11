/**
 * Nội dung bên trong một keypoint: learning item → tài liệu → khối nội dung.
 *
 * Hình dạng lấy từ model của app (`lib/src/lesson/data/models/`): một
 * learning item kiểu `theory` mang danh sách `documents`, mỗi tài liệu mang
 * một danh sách khối, mỗi khối có `type` quyết định cách vẽ.
 */
import 'server-only';

import { request, type PageBreak } from './api';
import type { MultiLang } from './content';

export type LearningItemType =
  'theory' | 'exercise' | 'roleplay' | 'video' | 'unknown';

export type ContentBlockType =
  | 'title'
  | 'text'
  | 'caption'
  | 'video'
  | 'image'
  | 'audio'
  | 'explanation'
  | 'unknown';

export interface ContentBlock {
  _id?: number;
  type?: ContentBlockType;
  data?: {
    content?: MultiLang;
    url?: MultiLang;
    thumbnail?: string;
  };
}

export interface LearningDocument {
  id?: number;
  speechBubble?: MultiLang;
  document?: ContentBlock[];
}

export interface LearningItem {
  _id: string;
  keypointId?: string;
  title?: MultiLang;
  description?: MultiLang;
  type?: LearningItemType;
  documents?: LearningDocument[];
  questions?: unknown[];
  index?: number;
}

export interface Keypoint {
  _id: string;
  title?: MultiLang;
  description?: MultiLang;
  index?: number;
  estimateCompleTimeNumber?: number;
  image?: string;
}

export function getKeypoint(id: string): Promise<Keypoint> {
  return request<Keypoint>(
    `/api/v1/courses-keypoints/${encodeURIComponent(id)}`,
  );
}

// KHÔNG có hàm lấy keypoint theo bài qua `/courses-keypoints?lessonId=`: API
// lặng lẽ bỏ qua `lessonId` và trả về MỌI keypoint (4 trang). Danh sách thật
// nằm sẵn trong `lesson.keypoints` (`getLesson`) và trong lộ trình khoá học.

export function getLearningItems(
  keypointId: string,
): Promise<PageBreak<LearningItem>> {
  const params = new URLSearchParams({
    keypointId,
    page: '1',
    take: '50',
    orderBy: 'index',
    order: 'asc',
  });
  return request<PageBreak<LearningItem>>(
    `/api/v1/courses-learning-items?${params.toString()}`,
  );
}

export interface Category {
  _id: string;
  title?: MultiLang;
  description?: MultiLang;
  image?: string;
}

export function getCategoryList(): Promise<PageBreak<Category>> {
  return request<PageBreak<Category>>(
    '/api/v1/categories?page=1&take=30&orderBy=createdAt&order=asc',
  );
}

// ---------------------------------------------------------------------------
// Quyền đọc keypoint (hạn mức miễn phí mỗi ngày)
// ---------------------------------------------------------------------------

export type KeypointAccessReason =
  | 'quota_disabled'
  | 'user_lesson'
  | 'premium'
  | 'already_completed'
  | 'todays_free_keypoint'
  | 'ticket_available'
  | 'quota_spent';

export interface KeypointAccess {
  /**
   * Chỉ số thẻ CAO NHẤT được đọc tới, `null` = không giới hạn. Server gửi thẳng
   * mức chặn chứ không gửi dữ kiện: luật phụ thuộc lịch sử học, client tự tính
   * thì phải được kể cả lịch sử.
   */
  cardCap: number | null;
  reason: KeypointAccessReason | string;
  quota: {
    limit: number;
    used: number;
    remaining: number;
    claimedKeypointId: string | null;
  } | null;
}

/**
 * Không bao giờ cache — API cũng dặn vậy: giữ câu trả lời một phút là vẫn
 * khoá sau khi người học đã có lượt, hoặc vẫn mở sau khi lượt đã hết.
 *
 * Lỗi thì trả `null` và trang mở hết nội dung: app cũng "mở khi không đánh giá
 * được", một bức tường không xác định được không được phép giấu nội dung.
 */
export function getKeypointAccess(id: string): Promise<KeypointAccess | null> {
  return request<KeypointAccess>(
    `/api/v1/keypoint-access/${encodeURIComponent(id)}`,
    { revalidate: 0 },
  ).catch(() => null);
}

// ---------------------------------------------------------------------------
// Thẻ đã lưu
// ---------------------------------------------------------------------------

export function getSavedCardIds(): Promise<string[]> {
  return request<string[]>('/api/v1/saved-cards/ids', { revalidate: 0 });
}

export interface SavedCardItem {
  _id?: string;
  keypointId: string;
  lessonId?: string;
  courseId?: string;
  title?: MultiLang;
  description?: MultiLang;
  image?: string;
  recap?: MultiLang;
  recapText?: string;
  courseTitle?: MultiLang;
  createdAt?: string;
}

export function getSavedCardPage(
  page = 1,
  take = 30,
): Promise<PageBreak<SavedCardItem>> {
  return request<PageBreak<SavedCardItem>>(
    `/api/v1/saved-cards?page=${page}&take=${take}`,
    { revalidate: 0 },
  );
}

// ---------------------------------------------------------------------------
// Dựng thẻ đọc từ learning item — cùng luật với app
// ---------------------------------------------------------------------------

/**
 * Phần tóm tắt ("Bỏ túi ngay") của keypoint, xác định theo VỊ TRÍ như
 * `resolveTakeawaySummary` của app chứ không dò nội dung: các theory một trang
 * nằm CUỐI, sau theory nhiều trang cuối cùng, là phần tóm tắt. Chúng gập vào
 * thẻ tóm tắt thay vì hiện thành thẻ riêng. Nếu mọi theory đều một trang thì
 * không có phần tóm tắt — gập hết là không còn gì để đọc.
 */
export function resolveTakeaway(items: LearningItem[]): {
  hidden: Set<number>;
  text: MultiLang | null;
} {
  const theory = items
    .map((item, index) => ({ item, index }))
    .filter(({ item }) => item.type === 'theory');
  const trailing: number[] = [];
  for (const { item, index } of [...theory].reverse()) {
    if ((item.documents?.length ?? 0) !== 1) break;
    trailing.push(index);
  }
  if (trailing.length === 0 || trailing.length === theory.length) {
    return { hidden: new Set(), text: null };
  }
  for (const index of trailing) {
    const text = flattenTakeaway(items[index]);
    if (text.vi || text.en) return { hidden: new Set(trailing), text };
  }
  return { hidden: new Set(), text: null };
}

/** Gộp các khối chữ của trang đầu thành một đoạn, bỏ dòng tiêu đề 🔑 và thẻ HTML. */
function flattenTakeaway(item: LearningItem): MultiLang {
  const blocks = item.documents?.[0]?.document ?? [];
  const pick = (lang: keyof MultiLang) => {
    const joined = blocks
      .filter((block) => block.type === 'text')
      .map((block) => block.data?.content?.[lang]?.trim() ?? '')
      .filter(Boolean)
      .join('\n\n')
      .replace(/<br\s*\/?>/gi, '\n')
      .replace(/<[^>]*>/g, '');
    const lines = joined.split('\n').map((line) => line.trim());
    while (lines.length && (!lines[0] || lines[0].startsWith('🔑'))) {
      lines.shift();
    }
    return lines.join('\n').trim();
  };
  return {
    vi: pick('vi'),
    en: pick('en'),
    zh: pick('zh'),
    ja: pick('ja'),
    ko: pick('ko'),
  };
}

// ---------------------------------------------------------------------------
// Lối vào ôn tập / khởi động trên trang chủ
// ---------------------------------------------------------------------------

/** Chỉ cần số phần đến hạn ôn — trang `/on-tap` tự nạp chi tiết. */
export function getSpacedReviewDueCount(): Promise<number> {
  return request<{ dueCount?: number }>('/api/v1/spaced-review/today', {
    revalidate: 0,
  }).then((data) => data?.dueCount ?? 0);
}

/**
 * Số câu khởi động hôm nay. Rỗng nghĩa là người dùng chưa học gì để khởi động
 * lại — thẻ trên trang chủ phải nói vậy thay vì dẫn vào một màn trống.
 */
export function getDailyWarmUpCount(): Promise<number> {
  return request<{ questions?: unknown[] }>(
    '/api/v1/courses-user-progress/daily-warm-up',
    { revalidate: 0 },
  ).then((data) => data?.questions?.length ?? 0);
}
