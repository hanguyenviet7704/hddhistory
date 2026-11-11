import Link from 'next/link';

import { AuthShell } from '@/components/account/auth-shell';
import { linkButton } from '@/components/account/link-classes';
import { SUPPORT_FANPAGE_URL } from '@/lib/account';

/**
 * Chưa có luồng khôi phục mật khẩu để làm theo.
 *
 * App khai báo `forgot-password` → OTP → `reset-password`, nhưng cả ba màn ở app
 * đều là khung rỗng (nút không làm gì) và API trả 404 cho mọi endpoint phía sau.
 * Dựng form gửi OTP ở đây là hứa một việc không ai làm được; trang này nói thật
 * và chỉ chỗ có người giúp.
 */
export default function ForgotPasswordPage() {
  return (
    <AuthShell subtitle="Quên mật khẩu?">
      <div className="rounded-xl border border-hairline bg-surface p-4 text-sm text-ink-muted">
        <p className="font-semibold text-ink">
          Chưa thể tự khôi phục mật khẩu
        </p>
        <p className="mt-2">
          Máy chủ chưa hỗ trợ gửi mã OTP hay đặt lại mật khẩu.
        </p>
        <p className="mt-2">
          Nếu vẫn không đăng nhập được, hãy nhắn cho chúng tôi qua Fanpage.
        </p>
      </div>

      <div className="mt-4 flex flex-col gap-2">
        <a
          href={SUPPORT_FANPAGE_URL}
          target="_blank"
          rel="noopener noreferrer"
          className={linkButton.secondary}
        >
          Liên hệ Fanpage
        </a>
        <Link href="/dang-nhap" className={linkButton.ghost}>
          Quay lại đăng nhập
        </Link>
      </div>
    </AuthShell>
  );
}
