/**
 * Gọi hddhistory-api.
 *
 * CHỈ chạy phía máy chủ: token nằm trong cookie httpOnly nên client không đọc
 * được, và gọi từ máy chủ tránh luôn CORS — API không mở CORS cho cổng này.
 */
import 'server-only';

import { getAccessToken } from './session';

const BASE_URL = process.env.API_BASE_URL ?? 'http://localhost:4098';

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

interface RequestOptions {
  method?: 'GET' | 'POST' | 'PUT' | 'PATCH' | 'DELETE';
  body?: unknown;
  /** Bỏ qua token — dùng cho đăng nhập/đăng ký. */
  anonymous?: boolean;
  /** Giây. 0 = luôn gọi mới. Mặc định 30. */
  revalidate?: number;
}

export async function request<T>(
  path: string,
  options: RequestOptions = {},
): Promise<T> {
  const { method = 'GET', body, anonymous = false, revalidate = 30 } = options;

  const headers: Record<string, string> = {
    // App gửi header này ở mọi request; API dùng nó để chọn ngôn ngữ nội dung.
    lang: 'vi',
    // Phút lệch UTC, giống app gửi ở mọi request. API dùng nó để chia ngày cho
    // chuỗi ngày học, hạn mức keypoint/ngày và lịch nhắc của Coach; thiếu thì
    // tính theo UTC, và học lúc 0h–7h giờ Việt Nam bị ghi vào hôm trước. Web
    // chỉ phục vụ tiếng Việt nên cố định múi giờ Việt Nam.
    'x-timezone-offset': '420',
  };
  // FormData (tải tệp lên) để fetch tự đặt Content-Type kèm boundary; đặt tay
  // là mất boundary và API không tách được các phần.
  const isForm = body instanceof FormData;
  if (body && !isForm) headers['Content-Type'] = 'application/json';
  if (!anonymous) {
    const token = await getAccessToken();
    if (token) headers.Authorization = `Bearer ${token}`;
  }

  let res: Response;
  try {
    res = await fetch(`${BASE_URL}${path}`, {
      method,
      headers,
      body: isForm ? body : body ? JSON.stringify(body) : undefined,
      // Chỉ GET mới được cache; POST luôn phải đi thật.
      ...(method === 'GET'
        ? { next: { revalidate } }
        : { cache: 'no-store' as const }),
    });
  } catch (error) {
    // fetch chỉ ném khi không nối được máy chủ — tách khỏi lỗi HTTP để màn
    // hình nói đúng chuyện gì đang xảy ra.
    throw new ApiError(
      `Không kết nối được API tại ${BASE_URL}: ${(error as Error).message}`,
      0,
    );
  }

  const text = await res.text();
  let parsed: BaseResponse<T> | { message?: string } | null = null;
  try {
    parsed = text ? JSON.parse(text) : null;
  } catch {
    parsed = null;
  }

  if (!res.ok) {
    const message =
      (parsed && 'message' in parsed && parsed.message) ||
      `API trả về ${res.status}`;
    throw new ApiError(String(message), res.status);
  }

  return (parsed as BaseResponse<T>).data;
}

/** GET trả về một trang phân trang của API. */
export interface PageBreak<T> {
  currentPage: number;
  totalPages: number;
  items: T[];
}
