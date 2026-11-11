/**
 * Kết quả trả về từ server action cho client component.
 *
 * Server action không nên ném lỗi ra client: Next che thông điệp lỗi ở bản
 * production, người dùng chỉ thấy một màn hình lỗi chung chung. Trả về một
 * giá trị có `error` bằng tiếng Việt thì form tự hiện được đúng chuyện gì sai.
 */
import { ApiError } from './api';

export type ActionResult<T = undefined> =
  | { ok: true; data: T; error?: undefined }
  | { ok: false; error: string; data?: undefined };

/** Chuyển một lỗi bất kỳ thành câu tiếng Việt đọc được. */
export function describeError(error: unknown): string {
  if (error instanceof ApiError) {
    if (error.status === 0) return 'Không kết nối được máy chủ. Thử lại sau.';
    if (error.status === 401) return 'Phiên đăng nhập đã hết. Đăng nhập lại.';
    if (error.status === 403) return 'Bạn không có quyền làm việc này.';
    if (error.status === 404) return 'Không tìm thấy nội dung này.';
    if (error.status === 429) return 'Bạn thao tác quá nhanh. Chờ một chút rồi thử lại.';
    if (error.status >= 500) return 'Máy chủ đang gặp sự cố. Thử lại sau.';
    return error.message;
  }
  return error instanceof Error ? error.message : String(error);
}

/** Chạy một lời gọi API và gói kết quả, không bao giờ ném. */
export async function attempt<T>(run: () => Promise<T>): Promise<ActionResult<T>> {
  try {
    return { ok: true, data: await run() };
  } catch (error) {
    return { ok: false, error: describeError(error) };
  }
}
