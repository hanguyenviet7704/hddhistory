import Link from 'next/link';

import { Avatar } from '@/components/account/avatar';
import { DeleteAccount } from '@/components/account/delete-account';
import { rowCard } from '@/components/account/link-classes';
import { LogoutButton } from '@/components/logout-button';
import { Notice, SectionHeader } from '@/components/section';
import {
  SUPPORT_FANPAGE_URL,
  TERMS_URL,
  getMe,
} from '@/lib/account';
import { getSessionUser } from '@/lib/session';

export default async function ProfilePage() {
  const [session, me] = await Promise.all([
    getSessionUser(),
    // Hồ sơ đầy đủ lấy từ API; cookie chỉ giữ đủ để dựng khung.
    getMe().catch(() => null),
  ]);

  const name = me?.name || session?.name || '';
  const email = me?.email || session?.email || '';

  return (
    <div className="pt-5">
      <h1 className="text-2xl font-bold tracking-tight text-brand-900">
        Hồ sơ
      </h1>

      <div className="mt-4 flex items-center gap-4 rounded-xl border border-hairline bg-surface p-4">
        <Avatar src={me?.avatar} name={name} size={64} />
        <div className="min-w-0 flex-1">
          <p className="truncate text-lg font-semibold text-ink">
            {name || 'Người học'}
          </p>
          {email ? (
            <p className="truncate text-sm text-ink-muted">{email}</p>
          ) : null}
          {me === null ? (
            <p className="mt-1 text-sm text-ink-faint">
              Không tải được hồ sơ từ máy chủ — đang hiện thông tin lưu trong phiên.
            </p>
          ) : null}
        </div>
        <Link
          href="/ho-so/thong-tin"
          className="shrink-0 rounded-xl px-3 py-2 text-sm font-semibold text-brand-700 transition hover:bg-brand-100"
        >
          Sửa
        </Link>
      </div>

      <SectionHeader title="Học tập" />
      <Link href="/tien-do" className={rowCard}>
        <span className="flex-1">
          <span className="block font-semibold text-ink">Tiến độ</span>
          <span className="block text-sm text-ink-muted">
            Chuỗi ngày học, hành trình tuần, thành tích, nhật ký học tập
          </span>
        </span>
        <span aria-hidden className="text-brand-700">
          →
        </span>
      </Link>

      <SectionHeader title="Tài khoản" />
      <div className="rounded-xl border border-hairline bg-surface p-4">
        <p className="font-semibold text-ink">Mật khẩu</p>
        <p className="mt-1 text-sm text-ink-muted">
          Máy chủ chưa hỗ trợ đổi hay đặt lại mật khẩu trên web.
        </p>
      </div>

      <SectionHeader title="Hỗ trợ" />
      <ul className="space-y-2">
        <li>
          <a
            href={SUPPORT_FANPAGE_URL}
            target="_blank"
            rel="noopener noreferrer"
            className={rowCard}
          >
            <span className="flex-1">
              <span className="block font-semibold text-ink">Liên hệ Fanpage</span>
              <span className="block text-sm text-ink-muted">
                Cần giúp đỡ? Nhắn với chúng tôi
              </span>
            </span>
            <span aria-hidden className="text-brand-700">
              ↗
            </span>
          </a>
        </li>
        <li>
          <a
            href={TERMS_URL}
            target="_blank"
            rel="noopener noreferrer"
            className={rowCard}
          >
            <span className="flex-1 font-semibold text-ink">
              Điều khoản &amp; Điều kiện
            </span>
            <span aria-hidden className="text-brand-700">
              ↗
            </span>
          </a>
        </li>
      </ul>

      <SectionHeader title="Chưa có trên web" />
      <Notice>
        Gói Premium chỉ mua, khôi phục và quản lý được trong ứng dụng di động
        (thanh toán qua App Store / Google Play). Thông báo đẩy, bài tập nói (ghi
        âm), đổi giao diện nền và widget màn hình chính cũng chỉ có trên app.
      </Notice>

      <div className="mt-6 space-y-3">
        <LogoutButton />
        <DeleteAccount />
      </div>
    </div>
  );
}
