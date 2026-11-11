/**
 * Nội dung học: kỹ năng, khoá học, bài học, tiến độ.
 *
 * Hình dạng dữ liệu lấy từ model của app (`hddhistory-flutter/lib/src/course`)
 * và từ chính các lời gọi app thực hiện lúc chạy, nên tham số truy vấn ở đây
 * giống hệt app chứ không phải đoán.
 */
import 'server-only';

import { request, type PageBreak } from './api';

/**
 * Chuỗi đa ngữ của API. App chỉ còn tiếng Việt nhưng server vẫn trả đủ các
 * trường, nên vẫn giữ chuỗi dự phòng: nội dung mới backfill một nửa vẫn hiện
 * được chữ nào đó thay vì để trống.
 */
export interface MultiLang {
  vi?: string;
  en?: string;
  zh?: string;
  ja?: string;
  ko?: string;
}

export function text(value: MultiLang | string | undefined | null): string {
  if (!value) return '';
  if (typeof value === 'string') return value;
  return value.vi || value.en || value.zh || value.ja || value.ko || '';
}

export interface Category {
  _id: string;
  title?: MultiLang;
  description?: MultiLang;
  image?: string;
  icon?: string;
}

export interface Course {
  _id: string;
  title?: MultiLang;
  description?: MultiLang;
  image?: string;
  categoryId?: string;
  numberOfLesson?: number;
  numberOfLessonPassed?: number;
  author?: string;
  viewCount?: number;
}

export interface Lesson {
  _id: string;
  title?: MultiLang;
  description?: MultiLang;
  courseId?: string;
  index?: number;
  numberOfKeypoint?: number;
}

export interface Quote {
  _id?: string;
  content?: MultiLang;
  author?: string;
}

export function getCategories(): Promise<PageBreak<Category>> {
  return request<PageBreak<Category>>(
    '/api/v1/categories?page=1&take=20&orderBy=createdAt&order=asc',
  );
}

/** Khoá học đang học dở, mới nhất trước — nguồn của dải "Tiếp tục học". */
export function getMyCourses(page = 1, take = 10): Promise<PageBreak<Course>> {
  return request<PageBreak<Course>>(
    `/api/v1/courses-user-progress/my-course?page=${page}&take=${take}&orderBy=createdAt&order=desc&recent=true`,
  );
}

export async function getSuggestedCourses(limit = 6): Promise<Course[]> {
  // Endpoint này trả id khoá ở `courseId`, KHÔNG có `_id` như mọi danh sách
  // khoá học khác — để nguyên thì mọi thẻ gợi ý trỏ tới /khoa-hoc/undefined.
  const items = await request<(Course & { courseId?: string })[]>(
    `/api/v1/courses-user-progress/suggest-courses?limit=${limit}`,
  );
  return items.map(({ courseId, ...course }) => ({
    ...course,
    _id: course._id || courseId || '',
  }));
}

export function getRandomQuote(): Promise<Quote> {
  // Ngẫu nhiên thì cache là vô nghĩa — lấy mới mỗi lần vào trang.
  return request<Quote>('/api/v1/courses-quotes/random', { revalidate: 0 });
}

export function getCourses(
  page = 1,
  take = 20,
  search?: string,
): Promise<PageBreak<Course>> {
  const params = new URLSearchParams({
    page: String(page),
    take: String(take),
    orderBy: 'createdAt',
    order: 'desc',
  });
  if (search?.trim()) params.set('search', search.trim());
  return request<PageBreak<Course>>(`/api/v1/courses?${params.toString()}`);
}

export function getCourse(id: string): Promise<Course> {
  return request<Course>(`/api/v1/courses/${encodeURIComponent(id)}`);
}

export function getCourseLessons(
  courseId: string,
  take = 100,
): Promise<PageBreak<Lesson>> {
  const params = new URLSearchParams({
    courseId,
    page: '1',
    take: String(take),
    orderBy: 'index',
    order: 'asc',
  });
  return request<PageBreak<Lesson>>(
    `/api/v1/courses-lessons?${params.toString()}`,
  );
}

export function getSavedCourses(
  page = 1,
  take = 20,
): Promise<PageBreak<Course>> {
  return request<PageBreak<Course>>(
    `/api/v1/saved-courses?page=${page}&take=${take}&orderBy=createdAt&order=desc`,
  );
}

// ---------------------------------------------------------------------------
// Lộ trình khoá học
// ---------------------------------------------------------------------------

/**
 * Trạng thái học. API viết sai chính tả tên trường (`progess`) và app đọc đúng
 * tên sai đó — giữ nguyên, đừng "sửa" thành `progress` kẻo luôn đọc ra rỗng.
 */
export type ProgressState = 'not_started' | 'in_progress' | 'done';

export interface RoadmapKeypoint {
  _id: string;
  title?: MultiLang;
  description?: MultiLang;
  image?: string;
  estimateCompleTimeNumber?: number;
  progess?: ProgressState;
}

export interface RoadmapLesson {
  _id: string;
  /** `lesson` | `video` | `roleplay` | `output`. Web chỉ mở được `lesson`. */
  type?: string;
  title?: MultiLang;
  description?: MultiLang;
  image?: string;
  estimateCompleTimeNumber?: number;
  keypoints?: RoadmapKeypoint[];
  progess?: ProgressState;
}

export interface RoadmapNode {
  id?: string;
  title?: MultiLang;
  description?: MultiLang;
  lessons?: RoadmapLesson[];
  openingVideo?: RoadmapLesson | null;
  closingVideo?: RoadmapLesson | null;
  roleplay?: RoadmapLesson | null;
  output?: RoadmapLesson | null;
}

export interface RoadmapLevel {
  id?: number;
  level?: string;
  titleBadge?: MultiLang;
  lightBadge?: string;
  darkBadge?: string;
  nodes?: RoadmapNode[];
}

export interface Roadmap {
  _id?: string;
  courseId?: string;
  courseDescription?: MultiLang;
  levels?: RoadmapLevel[];
}

/**
 * Lộ trình kèm trạng thái học CỦA NGƯỜI ĐANG XEM — server gắn `progess` cho
 * từng bài và từng keypoint theo token. Vì thế không cache: vừa bấm "Hoàn
 * thành" mà quay lại vẫn thấy chưa xong thì người học sẽ bấm lại lần nữa.
 */
export function getRoadmap(courseId: string): Promise<Roadmap | null> {
  return request<Roadmap | null>(
    `/api/v1/courses/${encodeURIComponent(courseId)}/roadmap`,
    { revalidate: 0 },
  );
}

/** Một keypoint trong lộ trình, kèm bài học chứa nó. */
export interface RoadmapStop {
  lesson: RoadmapLesson;
  keypoint: RoadmapKeypoint;
}

/**
 * Trải lộ trình thành một hàng keypoint theo đúng thứ tự học: cấp độ → nút →
 * bài → keypoint. Bài không phải `lesson` (video, nhập vai, luyện nói) không có
 * keypoint đọc được trên web nên rơi ra ngoài.
 */
export function roadmapStops(roadmap: Roadmap | null): RoadmapStop[] {
  const stops: RoadmapStop[] = [];
  for (const level of roadmap?.levels ?? []) {
    for (const node of level.nodes ?? []) {
      for (const lesson of node.lessons ?? []) {
        if (lesson.type && lesson.type !== 'lesson') continue;
        for (const keypoint of lesson.keypoints ?? []) {
          stops.push({ lesson, keypoint });
        }
      }
    }
  }
  return stops;
}

/**
 * Chỗ "Tiếp tục học" trỏ tới: keypoint đầu tiên chưa xong. Trả `null` khi đã
 * học hết — lúc đó nút biến mất, giống app ẩn CTA khi khoá đã hoàn thành.
 */
export function nextUnfinished(stops: RoadmapStop[]): RoadmapStop | null {
  return stops.find((stop) => stop.keypoint.progess !== 'done') ?? null;
}

/** Đường dẫn trình đọc keypoint, mang theo bài học để ghi được tiến độ. */
export function keypointHref(keypointId: string, lessonId?: string): string {
  const base = `/phan/${encodeURIComponent(keypointId)}`;
  return lessonId ? `${base}?bai=${encodeURIComponent(lessonId)}` : base;
}

export interface LessonDetail extends Lesson {
  type?: string;
  image?: string;
  /** Kèm `progess` của người đang xem, như trong lộ trình. */
  keypoints?: RoadmapKeypoint[];
  estimateCompleTimeNumber?: number;
}

/** Bài học kèm danh sách keypoint và trạng thái học của từng cái — không cache. */
export function getLesson(id: string): Promise<LessonDetail> {
  return request<LessonDetail>(
    `/api/v1/courses-lessons/${encodeURIComponent(id)}`,
    { revalidate: 0 },
  );
}

export interface BadgeProgress {
  level?: string;
  lightBadge?: string;
  darkBadge?: string;
  titleBadge?: MultiLang;
  courseId?: string;
  courseTitle?: MultiLang;
  totalKeypoints?: number;
  completedKeypoints?: number;
  isCompleted?: boolean;
}

/** Huy hiệu từng cấp độ của khoá, kèm số keypoint đã xong. */
export function getBadgeProgress(courseId: string): Promise<BadgeProgress[]> {
  return request<BadgeProgress[]>(
    `/api/v1/courses-user-progress/badge-progress/${encodeURIComponent(courseId)}`,
    { revalidate: 0 },
  );
}

// ---------------------------------------------------------------------------
// Khoá đã lưu, xem gần đây, lịch sử tìm kiếm
// ---------------------------------------------------------------------------

/**
 * Chỉ danh sách id — app giữ trong một tập để vẽ dấu trang đặc/rỗng ở mọi chỗ
 * hiện khoá học, thay vì bắt mọi payload danh mục kèm cờ `isSaved`.
 */
export function getSavedCourseIds(): Promise<string[]> {
  return request<string[]>('/api/v1/saved-courses/ids', { revalidate: 0 });
}

export type SavedCourseStatus = 'up_next' | 'in_progress' | 'finished';

export interface SavedCourse extends Course {
  savedStatus?: SavedCourseStatus;
}

/** Danh sách đã lưu, lọc theo ba nhóm của app. Server tự tính nhóm từ tiến độ. */
export function getSavedCoursesByStatus(
  status?: SavedCourseStatus,
  page = 1,
  take = 30,
): Promise<PageBreak<SavedCourse>> {
  const params = new URLSearchParams({
    page: String(page),
    take: String(take),
  });
  if (status) params.set('status', status);
  return request<PageBreak<SavedCourse>>(
    `/api/v1/saved-courses?${params.toString()}`,
    { revalidate: 0 },
  );
}

/** Khoá vừa mở, mới nhất trước. App ghi mỗi lần nạp lộ trình. */
export function getRecentlyViewed(): Promise<Course[]> {
  return request<Course[]>('/api/v1/courses-recently-viewed', {
    revalidate: 0,
  });
}

export interface SearchHistoryEntry {
  query: string;
  updatedAt?: string;
}

export function getSearchHistory(): Promise<SearchHistoryEntry[]> {
  return request<SearchHistoryEntry[]>('/api/v1/courses-search-history', {
    revalidate: 0,
  });
}

// ---------------------------------------------------------------------------
// Khám phá
// ---------------------------------------------------------------------------

export type ExploreSectionType =
  'curated' | 'weeklyTop' | 'becauseYou' | 'topicChips';

export interface ExploreSection {
  type?: ExploreSectionType | string;
  /** Id bộ sưu tập; chỉ có ở dải `curated`. */
  id?: string;
  title?: MultiLang;
  courses?: Course[];
  /** Chỉ ở `becauseYou`: khoá vừa học xong mà gợi ý bám theo. */
  sourceCourse?: Course;
}

/**
 * Mọi dải của tab Khám phá trong một lời gọi, ĐÃ theo thứ tự hiển thị — thứ
 * tự là quyết định của server, kể cả chỗ đặt dải chủ đề (`topicChips` chỉ là
 * một mốc đánh dấu, danh mục chủ đề lấy riêng).
 */
export function getExplore(): Promise<{ sections: ExploreSection[] }> {
  return request<{ sections: ExploreSection[] }>('/api/v1/courses-explore', {
    revalidate: 60,
  });
}

// ---------------------------------------------------------------------------
// Trang chủ: banner và popup quảng bá
// ---------------------------------------------------------------------------

export interface BannerSlide {
  campaignKey: string;
  imageUrl: string;
  linkUrl?: string;
}

export interface HomeBanner {
  enabled?: boolean;
  visible?: boolean;
  imageUrl?: string;
  linkUrl?: string;
  slides?: BannerSlide[];
}

export interface HomePopup {
  enabled?: boolean;
  visible?: boolean;
  imageUrl?: string;
  linkUrl?: string;
  campaignKey?: string;
}

export function getHomeBanner(): Promise<HomeBanner> {
  return request<HomeBanner>('/api/v1/home-banner', { revalidate: 60 });
}

/**
 * Không cache: câu trả lời đổi ngay khi người dùng bấm vào popup (server ẩn
 * chiến dịch đó với họ), nên giữ bản cũ là hiện lại thứ họ vừa bấm.
 */
export function getHomePopup(): Promise<HomePopup> {
  return request<HomePopup>('/api/v1/home-popup', { revalidate: 0 });
}

/**
 * Vị trí của một keypoint trong lộ trình, cùng phần liền trước và liền sau —
 * cho nút trước/sau của trình đọc và "phần tiếp theo" ở màn hoàn thành. Hết
 * keypoint của bài thì "sau" là keypoint đầu của bài kế tiếp.
 */
export function stopNeighbours(
  stops: RoadmapStop[],
  keypointId: string,
): { index: number; previous: RoadmapStop | null; next: RoadmapStop | null } {
  const index = stops.findIndex((stop) => stop.keypoint._id === keypointId);
  if (index < 0) return { index, previous: null, next: null };
  return {
    index,
    previous: stops[index - 1] ?? null,
    next: stops[index + 1] ?? null,
  };
}
