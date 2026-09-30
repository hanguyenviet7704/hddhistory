'use server';

import { redirect } from 'next/navigation';

import { ApiError, request } from './api';
import { clearSession, saveSession, type SessionUser } from './session';

interface LoginResponse {
  token: { accessToken: string; refreshToken: string };
  user: { _id: string; name?: string; email?: string };
}

/**
 * Một `deviceId` cố định cho trình duyệt.
 *
 * API đếm và giới hạn thiết bị theo id này (xem `checkDevice` trong
 * auth.service). Nếu web sinh id mới mỗi lần đăng nhập, mỗi lần đăng nhập sẽ
 * chiếm một chỗ thiết bị và đẩy điện thoại của chính người dùng ra ngoài.
 */
const WEB_DEVICE = { deviceId: 'hddhistory-web', deviceName: 'Web' };

export async function login(
  _prev: { error?: string } | null,
  formData: FormData,
): Promise<{ error?: string }> {
  const email = String(formData.get('email') ?? '').trim();
  const password = String(formData.get('password') ?? '');

  if (!email || !password) {
    return { error: 'Nhập email và mật khẩu.' };
  }

  let data: LoginResponse;
  try {
    data = await request<LoginResponse>('/api/v1/users/login', {
      method: 'POST',
      anonymous: true,
      body: { email, password, device: WEB_DEVICE },
    });
  } catch (error) {
    if (error instanceof ApiError) {
      // 404 = không có tài khoản, 400/401 = sai mật khẩu. Nói bằng tiếng Việt
      // thay vì ném nguyên thông điệp của API ra cho người dùng đọc.
      if (error.status === 404) return { error: 'Không tìm thấy tài khoản này.' };
      if (error.status === 400 || error.status === 401) {
        return { error: 'Email hoặc mật khẩu không đúng.' };
      }
      return { error: error.message };
    }
    return { error: String(error) };
  }

  const user: SessionUser = {
    id: data.user._id,
    name: data.user.name ?? '',
    email: data.user.email ?? email,
  };
  await saveSession(data.token.accessToken, data.token.refreshToken, user);
  redirect('/');
}

export async function logout(): Promise<void> {
  await clearSession();
  redirect('/dang-nhap');
}
