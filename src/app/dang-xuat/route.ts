import { redirect } from 'next/navigation';

import { clearSession } from '@/lib/session';

/**
 * Xoá phiên rồi đưa về trang đăng nhập.
 *
 * Là route handler chứ không phải server component: Next chỉ cho ghi/xoá cookie
 * trong server action và route handler. Layout phát hiện token hỏng thì
 * chuyển hướng tới đây, vì bản thân nó không xoá cookie được.
 */
export async function GET() {
  await clearSession();
  redirect('/dang-nhap');
}
