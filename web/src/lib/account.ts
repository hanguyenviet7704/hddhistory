/**
 * Tài khoản của người đang đăng nhập.
 *
 * Hình dạng dò trực tiếp trên `GET /users/me` (API đã bỏ `password`,
 * `providerData`, `refreshToken` khỏi kết quả).
 */
import 'server-only';

import { request } from './api';

export interface Me {
  _id: string;
  name?: string;
  email?: string;
  /** URL ảnh trên CDN; app lưu bằng `PUT /users/:id { avatar }` sau khi tải lên. */
  avatar?: string;
  anonymous?: boolean;
  createdAt?: string;
}

/**
 * Không cache: vừa đổi tên hay ảnh xong mà trang hồ sơ còn hiện bản 30 giây
 * trước thì người dùng tưởng chưa lưu được.
 */
export const getMe = () => request<Me>('/api/v1/users/me', { revalidate: 0 });

/** Trang tải app — nơi tạo tài khoản (Apple/Google) cho tới khi API cho tự đặt mật khẩu. */
export const APP_DOWNLOAD_URL = 'https://meup.training';

/** Trang Facebook hỗ trợ — cùng địa chỉ mục "Liên hệ Fanpage" của app. */
export const SUPPORT_FANPAGE_URL =
  'https://www.facebook.com/profile.php?id=61586812343588';

/** Điều khoản — cùng địa chỉ mục "Điều khoản & Điều kiện" của app. */
export const TERMS_URL = 'https://meup.training/terms-and-conditions.html';
