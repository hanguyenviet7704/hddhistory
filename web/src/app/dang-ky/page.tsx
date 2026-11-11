import Link from 'next/link';
import { redirect } from 'next/navigation';

import { AuthShell } from '@/components/account/auth-shell';
import { linkButton } from '@/components/account/link-classes';
import { APP_DOWNLOAD_URL } from '@/lib/account';
import { getSessionUser } from '@/lib/session';

/**
 * Chưa mở đăng ký bằng email trên web.
 *
 * `POST /users/register` gán cùng một mật khẩu cố định cho MỌI tài khoản, và API
 * chưa có đường nào để đổi nó. Mở form đăng ký ở đây là tạo ra những tài khoản
 * mà ai biết email cũng đăng nhập được. App tạo tài khoản bằng Apple/Google,
 * nên chỉ người dùng tới đó cho tới khi API cho tự đặt mật khẩu.
 */
export default async function RegisterPage() {
  if (await getSessionUser()) redirect('/');

  return (
    <AuthShell subtitle="Tạo tài khoản">
      <div className="rounded-xl border border-hairline bg-surface p-4 text-sm text-ink-muted">
        <p className="font-semibold text-ink">Tạo tài khoản trên ứng dụng</p>
        <p className="mt-2">
          Hiện bạn tạo tài khoản HDDhistory bằng Apple hoặc Google trên ứng dụng
          di động. Web sẽ mở đăng ký bằng email khi máy chủ hỗ trợ tự đặt mật
          khẩu.
        </p>
      </div>

      <div className="mt-4 flex flex-col gap-2">
        <a
          href={APP_DOWNLOAD_URL}
          target="_blank"
          rel="noopener noreferrer"
          className={linkButton.primary}
        >
          Tải ứng dụng
        </a>
        <Link href="/dang-nhap" className={linkButton.ghost}>
          Quay lại đăng nhập
        </Link>
      </div>
    </AuthShell>
  );
}
