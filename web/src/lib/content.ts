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

export interface Skillset {
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
  skillsetId?: string;
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

export function getSkillsets(): Promise<PageBreak<Skillset>> {
  return request<PageBreak<Skillset>>(
    '/api/v1/skillsets?page=1&take=20&orderBy=createdAt&order=asc',
  );
}

/** Khoá học đang học dở, mới nhất trước — nguồn của dải "Tiếp tục học". */
export function getMyCourses(page = 1, take = 10): Promise<PageBreak<Course>> {
  return request<PageBreak<Course>>(
    `/api/v1/courses-user-progress/my-course?page=${page}&take=${take}&orderBy=createdAt&order=desc&recent=true`,
  );
}

export function getSuggestedCourses(limit = 6): Promise<Course[]> {
  return request<Course[]>(
    `/api/v1/courses-user-progress/suggest-courses?limit=${limit}`,
  );
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
