/** Lời gọi API cho đồ thị tri thức lịch sử. */
import 'server-only';

import { ApiError, request } from './api';
import type { KgEntityProfile, KgEntitySummary, KgRelatedEntity } from './kg';

export async function searchEntities(
  query: string,
  limit = 30,
): Promise<KgEntitySummary[]> {
  const params = new URLSearchParams({ limit: String(limit) });
  if (query.trim()) params.set('q', query.trim());
  return request<KgEntitySummary[]>(
    `/api/v1/knowledge-graph/entities?${params.toString()}`,
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
