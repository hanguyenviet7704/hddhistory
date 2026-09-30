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
  | 'theory'
  | 'exercise'
  | 'roleplay'
  | 'video'
  | 'unknown';

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
}

export function getKeypoint(id: string): Promise<Keypoint> {
  return request<Keypoint>(
    `/api/v1/courses-keypoints/${encodeURIComponent(id)}`,
  );
}

export function getKeypoints(lessonId: string): Promise<PageBreak<Keypoint>> {
  const params = new URLSearchParams({
    lessonId,
    page: '1',
    take: '100',
    orderBy: 'index',
    order: 'asc',
  });
  return request<PageBreak<Keypoint>>(
    `/api/v1/courses-keypoints?${params.toString()}`,
  );
}

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

export interface Skillset {
  _id: string;
  title?: MultiLang;
  description?: MultiLang;
  image?: string;
}

export function getSkillsetList(): Promise<PageBreak<Skillset>> {
  return request<PageBreak<Skillset>>(
    '/api/v1/skillsets?page=1&take=30&orderBy=createdAt&order=asc',
  );
}
