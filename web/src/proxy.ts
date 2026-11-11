import { NextResponse, type NextRequest } from 'next/server';

import {
  ACCESS_COOKIE,
  REFRESH_COOKIE,
  USER_COOKIE,
  WEB_DEVICE,
  sessionCookieOptions,
} from '@/lib/session-cookies';

const BASE_URL = process.env.API_BASE_URL ?? 'http://localhost:4000';

/** Làm mới khi token còn dưới một ngày — access token của API sống 7 ngày. */
const REFRESH_BEFORE_SECONDS = 60 * 60 * 24;

/**
 * Đọc `exp` của JWT mà KHÔNG kiểm chữ ký.
 *
 * Proxy không giữ khoá bí mật của API và cũng không cần: nó chỉ hỏi "token này
 * sắp hết hạn chưa" để quyết định có làm mới hay không. Token giả mạo vẫn bị
 * chính API từ chối ở lời gọi tiếp theo.
 */
function expiresAt(token: string): number | null {
  try {
    const payload = token.split('.')[1];
    if (!payload) return null;
    const json = JSON.parse(
      atob(payload.replace(/-/g, '+').replace(/_/g, '/')),
    ) as { exp?: number };
    return typeof json.exp === 'number' ? json.exp : null;
  } catch {
    return null;
  }
}

/**
 * Làm mới access token trước khi trang được dựng.
 *
 * Phải ở proxy: server component không được ghi cookie, nên nếu để trang tự
 * phát hiện token hết hạn thì nó chỉ còn cách đá người dùng ra đăng nhập lại —
 * dù refresh token (30 ngày) vẫn còn tốt.
 */
export async function proxy(request: NextRequest) {
  const access = request.cookies.get(ACCESS_COOKIE)?.value;
  const refresh = request.cookies.get(REFRESH_COOKIE)?.value;
  const rawUser = request.cookies.get(USER_COOKIE)?.value;
  if (!access || !refresh || !rawUser) return NextResponse.next();

  const exp = expiresAt(access);
  const now = Math.floor(Date.now() / 1000);
  if (exp !== null && exp - now > REFRESH_BEFORE_SECONDS) {
    return NextResponse.next();
  }

  let userId: string | undefined;
  try {
    userId = (JSON.parse(rawUser) as { id?: string }).id;
  } catch {
    return NextResponse.next();
  }
  if (!userId) return NextResponse.next();

  let accessToken: string | undefined;
  try {
    const res = await fetch(
      `${BASE_URL}/api/v1/users/${encodeURIComponent(userId)}/refresh-token`,
      {
        method: 'POST',
        headers: { 'Content-Type': 'application/json', lang: 'vi' },
        body: JSON.stringify({ refreshToken: refresh, device: WEB_DEVICE }),
        cache: 'no-store',
      },
    );
    if (res.ok) {
      const body = (await res.json()) as {
        data?: { token?: { accessToken?: string } };
      };
      accessToken = body.data?.token?.accessToken;
    }
  } catch {
    // API không với tới được: để yên, layout sẽ tự hiện lỗi mạng thay vì
    // đăng xuất người dùng vì một sự cố không phải của họ.
    return NextResponse.next();
  }

  // Làm mới thất bại (refresh hết hạn, thiết bị bị đẩy ra): để nguyên, layout
  // nhận 401 từ /users/me và đưa về trang đăng nhập như trước.
  if (!accessToken) return NextResponse.next();

  // Ghi token mới vào CẢ request đang đi tiếp (để chính lần dựng trang này
  // dùng token mới) lẫn response (để trình duyệt lưu lại).
  request.cookies.set(ACCESS_COOKIE, accessToken);
  const response = NextResponse.next({
    request: { headers: request.headers },
  });
  response.cookies.set(ACCESS_COOKIE, accessToken, sessionCookieOptions);
  return response;
}

export const config = {
  // Bỏ qua tài nguyên tĩnh và trang đăng nhập/đăng xuất: chúng không gọi API
  // bằng token nên không có gì để làm mới.
  matcher: [
    '/((?!_next/static|_next/image|favicon.ico|fonts/|.*\\.(?:svg|png|jpg|jpeg|webp|ico)$|dang-nhap|dang-xuat).*)',
  ],
};
