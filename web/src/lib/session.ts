/**
 * Phiên đăng nhập, lưu trong cookie httpOnly.
 *
 * Không dùng localStorage như app: ở web, localStorage đọc được bằng JavaScript
 * nên một lỗi XSS là mất token. Cookie httpOnly thì script không chạm tới được,
 * và server component đọc thẳng được mà không cần bước gửi token nào.
 */
import 'server-only';

import { cookies } from 'next/headers';

const ACCESS = 'hdd_access';
const REFRESH = 'hdd_refresh';
const USER = 'hdd_user';

/** 30 ngày — khớp tuổi refresh token của API. */
const MAX_AGE = 60 * 60 * 24 * 30;

export interface SessionUser {
  id: string;
  name: string;
  email: string;
}

export async function getAccessToken(): Promise<string | null> {
  return (await cookies()).get(ACCESS)?.value ?? null;
}

export async function getRefreshToken(): Promise<string | null> {
  return (await cookies()).get(REFRESH)?.value ?? null;
}

export async function getSessionUser(): Promise<SessionUser | null> {
  const raw = (await cookies()).get(USER)?.value;
  if (!raw) return null;
  try {
    return JSON.parse(raw) as SessionUser;
  } catch {
    // Cookie hỏng thì coi như chưa đăng nhập, đừng làm sập cả trang.
    return null;
  }
}

export async function saveSession(
  accessToken: string,
  refreshToken: string,
  user: SessionUser,
): Promise<void> {
  const jar = await cookies();
  const base = {
    httpOnly: true,
    sameSite: 'lax' as const,
    path: '/',
    maxAge: MAX_AGE,
    // Chỉ bật secure khi chạy https thật: máy cá nhân chạy http://localhost,
    // cookie secure sẽ bị trình duyệt bỏ và không ai đăng nhập được.
    secure: process.env.NODE_ENV === 'production',
  };
  jar.set(ACCESS, accessToken, base);
  jar.set(REFRESH, refreshToken, base);
  jar.set(USER, JSON.stringify(user), base);
}

export async function clearSession(): Promise<void> {
  const jar = await cookies();
  for (const name of [ACCESS, REFRESH, USER]) jar.delete(name);
}
