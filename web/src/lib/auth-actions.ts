'use server';

import { redirect } from 'next/navigation';

import { ApiError, request } from './api';
import { clearSession, saveSession, type SessionUser } from './session';
import { WEB_DEVICE } from './session-cookies';

interface LoginResponse {
  token: { accessToken: string; refreshToken: string };
  user: { _id: string; name?: string; email?: string };
}

/** Đăng nhập rồi ghi phiên. */
async function signIn(email: string, password: string): Promise<void> {
  const data = await request<LoginResponse>('/api/v1/users/login', {
    method: 'POST',
    anonymous: true,
    body: { email, password, device: WEB_DEVICE },
  });
  const user: SessionUser = {
    id: data.user._id,
    name: data.user.name ?? '',
    email: data.user.email ?? email,
  };
  await saveSession(data.token.accessToken, data.token.refreshToken, user);
}

export async function login(
  _prev: { error?: string } | null,
  formData: FormData,
): Promise<{ error?: string }> {
  const email = String(formData.get('email') ?? '').trim();
  const password = String(formData.get('password') ?? '');

  if (!email || !password) {
    return { error: 'Nhập email và mật khẩu.' };
  }

  try {
    await signIn(email, password);
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

  redirect('/');
}

export async function logout(): Promise<void> {
  // Báo API gỡ thiết bị "Web" khỏi tài khoản: AuthGuard kiểm tra thiết bị ở mỗi
  // request, nên token cũ (nếu bị lộ) cũng hết hiệu lực, và chỗ thiết bị được
  // trả lại. Lỗi ở đây không được chặn việc đăng xuất khỏi trình duyệt.
  await request('/api/v1/users/logout', {
    method: 'POST',
    body: { device: WEB_DEVICE },
  }).catch(() => undefined);
  await clearSession();
  redirect('/dang-nhap');
}
