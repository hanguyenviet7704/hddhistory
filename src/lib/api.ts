/**
 * Gọi API đồ thị tri thức của hddhistory-api.
 *
 * CHỈ chạy phía máy chủ (server component / route handler): token nằm trong
 * biến môi trường không có tiền tố NEXT_PUBLIC_, nên nó không bao giờ đi xuống
 * trình duyệt. Gọi từ máy chủ cũng tránh luôn CORS — API không mở CORS cho
 * cổng của web này.
 */
import 'server-only';

import type {
  KgEntityProfile,
  KgEntitySummary,
  KgRelatedEntity,
} from './kg';

const BASE_URL = process.env.API_BASE_URL ?? 'http://localhost:4099';
const TOKEN = process.env.API_TOKEN ?? '';

/** Bao ngoài phần `data` mà ResponseInterceptor của NestJS thêm vào. */
interface BaseResponse<T> {
  statusCode: number;
  message: string;
  data: T;
}

export class ApiError extends Error {
  constructor(
    message: string,
    readonly status: number,
  ) {
    super(message);
  }
}

async function get<T>(path: string): Promise<T> {
  let res: Response;
  try {
    res = await fetch(`${BASE_URL}${path}`, {
      headers: { Authorization: `Bearer ${TOKEN}` },
      // Dữ liệu lịch sử đổi rất chậm, nhưng trong lúc còn soạn nội dung thì
      // cache lâu chỉ gây khó hiểu. 30 giây đủ để một trang không gọi lại API
      // nhiều lần mà vẫn thấy thay đổi gần như ngay.
      next: { revalidate: 30 },
    });
  } catch (error) {
    // fetch chỉ ném khi không nối được máy chủ — phân biệt rõ với lỗi HTTP để
    // màn hình nói đúng chuyện gì đang xảy ra.
    throw new ApiError(
      `Không kết nối được API tại ${BASE_URL}: ${(error as Error).message}`,
      0,
    );
  }

  if (!res.ok) {
    throw new ApiError(`API trả về ${res.status}`, res.status);
  }

  const body = (await res.json()) as BaseResponse<T>;
  return body.data;
}

export async function searchEntities(
  query: string,
  limit = 30,
): Promise<KgEntitySummary[]> {
  const params = new URLSearchParams({ limit: String(limit) });
  if (query.trim()) params.set('q', query.trim());
  return get<KgEntitySummary[]>(
    `/api/v1/knowledge-graph/entities?${params.toString()}`,
  );
}

/** null khi API trả 404 — thực thể không tồn tại, không phải lỗi hệ thống. */
export async function getEntityProfile(
  id: string,
): Promise<KgEntityProfile | null> {
  try {
    return await get<KgEntityProfile>(
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
  return get<KgRelatedEntity[]>(
    `/api/v1/knowledge-graph/entities/${encodeURIComponent(id)}/related?${params.toString()}`,
  );
}
