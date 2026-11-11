/**
 * Tên và tuỳ chọn cookie phiên — dùng chung cho `session.ts` (server component,
 * server action) và `proxy.ts` (chạy trước khi dựng trang).
 *
 * Tách riêng vì `session.ts` nhập `next/headers` + `server-only`, còn proxy chỉ
 * được làm việc với cookie qua `NextRequest`/`NextResponse`.
 */
export const ACCESS_COOKIE = 'hdd_access';
export const REFRESH_COOKIE = 'hdd_refresh';
export const USER_COOKIE = 'hdd_user';

/** 30 ngày — khớp tuổi refresh token của API. */
export const SESSION_MAX_AGE = 60 * 60 * 24 * 30;

/**
 * Một `deviceId` cố định cho trình duyệt.
 *
 * API đếm và giới hạn thiết bị theo id này (xem `checkDevice` trong
 * auth.service), và làm mới token cũng phải gửi đúng id lúc đăng nhập. Nếu web
 * sinh id mới mỗi lần, mỗi lần đăng nhập sẽ chiếm một chỗ thiết bị và đẩy điện
 * thoại của chính người dùng ra ngoài.
 */
export const WEB_DEVICE = { deviceId: 'hddhistory-web', deviceName: 'Web' };

export const sessionCookieOptions = {
  httpOnly: true,
  sameSite: 'lax' as const,
  path: '/',
  maxAge: SESSION_MAX_AGE,
  // Chỉ bật secure khi chạy https thật: máy cá nhân chạy http://localhost,
  // cookie secure sẽ bị trình duyệt bỏ và không ai đăng nhập được.
  secure: process.env.NODE_ENV === 'production',
};
