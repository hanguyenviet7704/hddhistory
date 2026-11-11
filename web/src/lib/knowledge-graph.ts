/** Lời gọi API cho đồ thị tri thức lịch sử. */
import 'server-only';

import { ApiError, request } from './api';
import type {
  KgEntityLesson,
  KgEntityProfile,
  KgEntitySummary,
  KgOverview,
  KgRelatedEntity,
} from './kg';

/**
 * Tìm theo tên hoặc bí danh; không có từ khoá mà có bộ lọc thì thành danh
 * sách duyệt (một thời kỳ, một loại). 300 là trần của API — đủ cả đồ thị.
 */
export async function searchEntities(
  query: string,
  filters: { type?: string; periodId?: string } = {},
  limit = 50,
): Promise<KgEntitySummary[]> {
  const params = new URLSearchParams({ limit: String(limit) });
  if (query.trim()) params.set('q', query.trim());
  if (filters.type) params.set('type', filters.type);
  if (filters.periodId) params.set('periodId', filters.periodId);
  return request<KgEntitySummary[]>(
    `/api/v1/knowledge-graph/entities?${params.toString()}`,
    { revalidate: 300 },
  );
}

/** Mục lục: thời kỳ theo thứ tự kèm số thực thể, và quy mô đồ thị. */
export function getOverview(): Promise<KgOverview> {
  return request<KgOverview>('/api/v1/knowledge-graph/overview', {
    revalidate: 300,
  });
}

/** Bài học nhắc tới thực thể — nối trang tra cứu về đúng chỗ học. */
export function getEntityLessons(id: string): Promise<KgEntityLesson[]> {
  return request<KgEntityLesson[]>(
    `/api/v1/courses-lessons/by-entity/${encodeURIComponent(id)}`,
    { revalidate: 300 },
  );
}

/** null khi API trả 404 — thực thể không tồn tại, không phải lỗi hệ thống. */
export async function getEntityProfile(
  id: string,
): Promise<KgEntityProfile | null> {
  try {
    return await request<KgEntityProfile>(
      `/api/v1/knowledge-graph/entities/${encodeURIComponent(id)}`,
    );
  } catch (error) {
    if (error instanceof ApiError && error.status === 404) return null;
    throw error;
  }
}

export async function getRelatedEntities(
  id: string,
  maxHops = 2,
  limit = 20,
): Promise<KgRelatedEntity[]> {
  const params = new URLSearchParams({
    maxHops: String(maxHops),
    limit: String(limit),
  });
  return request<KgRelatedEntity[]>(
    `/api/v1/knowledge-graph/entities/${encodeURIComponent(id)}/related?${params.toString()}`,
  );
}
